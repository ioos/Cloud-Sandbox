#!/home/ec2-user/.cargo/bin/nu

# Summarize DynamoDB batch job entries from the past week.
# Groups by name-tag, showing instance-type counts and unique job totals.
# Usage:
#   nu weekly_job_summary.nu <table-name>
#   nu weekly_job_summary.nu <table-name> --days 14
#   nu weekly_job_summary.nu <table-name> --region us-east-1
def main [
    table: string            # DynamoDB table name
    --days: int = 7          # Look-back window in days (default: 7)
    --region: string = ""    # AWS region (optional)
] {
    let now = (date now)
    let cutoff = ($now - ($days * 24 * 60 * 60 * 1_000_000_000 | into duration --unit ns))

    let region_flags = if $region != "" { ["--region" $region] } else { [] }

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

    # Parse all items into a flat record format first
    let parsed = $raw.Items | each { |item|
        let htime_str = ($item | get -o "human-time" | default {S: ""} | get S)
        {
            "name-tag":       ($item | get -o "name-tag"       | default {S: "(none)"} | get S)
            "instance-type":  ($item | get -o "instance-type"  | default {S: "(none)"} | get S)
            "instance-id":    ($item | get -o "instance-id"    | default {S: ""}       | get S)
            "started":        $htime_str
        }
    }

    # Filter to entries within the look-back window using where
    let items = $parsed
        | where { |row| $row.started != "" }
        | where { |row| ($row.started | into datetime --format "%Y-%m-%d %H:%M %Z") >= $cutoff }

    let total_instances = ($items | length)
    let unique_jobs     = ($items | each { |r| $r."name-tag" } | uniq | length )

    if $total_instances == 0 {
        print $"No jobs found in the last ($days) days."
        return
    }

    # --- Table 1: unique job names ---
    let by_job_type = (
    $items | each { |r| $r."name-tag" }
    )

    # --- Table 2: instance-type totals across all jobs ---
    let by_type = (
        $items
        | group-by { |row| $row."instance-type" }
        | transpose instance_type entries
        | each { |row| { "instance-type": $row.instance_type, "total-instances": ($row.entries | length) } }
        | sort-by "total-instances" --reverse
    )

    print $"\n=== Jobs in the last ($days) days  |  ($unique_jobs) unique jobs  |  ($total_instances) total instances ===\n"

    print "\n-- By instance type --"
    $by_type | table
}
