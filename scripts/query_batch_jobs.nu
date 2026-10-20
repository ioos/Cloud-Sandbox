#!/home/ec2-user/.cargo/bin/nu

# Query batch jobs from DynamoDB and show time status.
# Usage:
#   nu query_batch_jobs.nu <table-name>
#   nu query_batch_jobs.nu <table-name> --minutes-max 60
#   nu query_batch_jobs.nu <table-name> --running-only
#   example usage: ./query_batch_jobs.nu IOOS-Sandbox-Compute-Nodes --running-only
def main [
    table: string               # DynamoDB table name
    --minutes-max: int = 120    # Default max runtime in minutes (overrides per-item value when set)
    --region: string = ""       # AWS region (optional, uses env/config default if omitted)
    --running-only              # Filter to only instances currently in the 'running' EC2 state
] {
    let now = (date now)

    # Build the base command
    let region_flags = if $region != "" { ["--region" $region] } else { [] }

    # Fetch running EC2 instance IDs if --running-only is set
    let running_ids = if $running_only {
        print "Fetching running EC2 instances..."
        let ec2 = (
            aws ec2 describe-instances
                --filters "Name=instance-state-name,Values=running"
                --query "Reservations[*].Instances[*].InstanceId"
                --output json
                ...$region_flags
            | from json
            | flatten
        )
        $ec2
    } else {
        []
    }

    let raw = (
        aws dynamodb scan
            --table-name $table
            ...$region_flags
        | from json
    )

    if ($raw | get -o Items | is-empty) {
        print "No items found in table."
        return
    }

    let jobs = $raw.Items | each { |item|
        # Extract typed attribute values from DynamoDB JSON format
        let iid       = $item."instance-id".S
        # Skip non-running instances when --running-only is set
        if $running_only and ($iid not-in $running_ids) { return }

        let name      = ($item | get -o "name-tag" | default {S: ""} | get S)
        let itype     = ($item | get -o "instance-type" | default {S: ""} | get S)
        let user      = ($item | get -o username | default {S: ""} | get S)
        let htime_str = ($item | get -o "human-time" | default {S: ""} | get S)

        # Use per-item minutes-max if present, otherwise fall back to flag/default
        let mm = if ($item | get -o "minutes-max" | is-not-empty) {
            $item."minutes-max".N | into int
        } else {
            $minutes_max
        }

        # Parse the stored human-time string and compute deadline
        # Expected format: "2026-04-16 14:30 UTC"
        let start_dt = ($htime_str | into datetime --format "%Y-%m-%d %H:%M %Z")
        let deadline = ($start_dt + ($mm | into duration --unit min))
        let diff = ($deadline - $now)

        # Duration / duration gives a float number of minutes
        let diff_mins = ($diff / 1min | math round)

        let status = if $diff_mins > 0 {
            $"($diff_mins)m remaining"
        } else {
            $"($diff_mins | math abs)m overdue"
        }

        {
            "instance-id":   $iid
            "name-tag":      $name
            "type":          $itype
            "user":          $user
            "started":       $htime_str
            "max-min":       $mm
            "deadline":      ($deadline | format date "%Y-%m-%d %H:%M %Z")
            "status":        $status
            "_sort_key":     $diff_mins   # signed minutes: negative = overdue (sorts first)
        }
    }

    $jobs
        | sort-by _sort_key
        | reject _sort_key
        | table
}
