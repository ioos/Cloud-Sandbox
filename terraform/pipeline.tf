data "aws_iam_policy_document" "image_builder" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
      "imagebuilder:GetComponent",

    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:List",
      "s3:GetObject"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::${var.aws_s3_log_bucket}/image-builder/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:log-group:/aws/imagebuilder/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["*"]
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "kms:EncryptionContextKeys"

      values = [
        "aws:imagebuilder:arn"
      ]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:CalledVia"

      values = [
        "imagebuilder.amazonaws.com"
      ]
    }
  }
}
resource "aws_imagebuilder_image_pipeline" "headnode" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.headnode.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.headnode.arn
  name                             = "amazon-linux-baseline"
  status                           = "ENABLED"
  description                      = "Creates an Amazon Linux 2 image."

  schedule {
    schedule_expression = "cron(0 8 ? * tue)"
    # This cron expression states every Tuesday at 8 AM.
    pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
  }

  # Test the image after build
  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 60
  }

  tags = {
    "Name" = "headnode-pipeline"
  }
}
resource "aws_imagebuilder_image" "headnode" {
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.headnode.arn
  image_recipe_arn                 = aws_imagebuilder_image_recipe.headnode.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.headnode.arn

  depends_on = [
    data.aws_iam_policy_document.image_builder
  ]
}

resource "aws_imagebuilder_image_recipe" "headnode" {
  block_device_mapping {
    device_name = "/dev/xvdb"

    ebs {
      delete_on_termination = true
      volume_size           = var.ebs_root_vol_size
      volume_type           = "gp3"
    }
  }

  component {
    component_arn = aws_imagebuilder_component.fvcom.arn
  }

  name         = "amazon-linux-recipe"
  parent_image = "arn:${data.aws_partition.current.partition}:imagebuilder:${data.aws_region.current.name}:aws:image/amazon-linux-2-x86/x.x.x"
  version      = var.image_receipe_version
}

#resource "aws_s3_bucket_object" "cw_agent_upload" {
#  bucket = var.aws_s3_bucket_object
#  key    = "/files/amazon-cloudwatch-agent-linux.yml"
#  source = "${path.module}/files/amazon-cloudwatch-agent-linux.yml"
#  # If the md5 hash is different it will re-upload
#  etag = filemd5("${path.module}/files/amazon-cloudwatch-agent-linux.yml")
#}

data "aws_kms_key" "image_builder" {
  key_id = "alias/image-builder"
}

# Amazon Cloudwatch agent component
# resource "aws_imagebuilder_component" "cw_agent" {
#  name       = "amazon-cloudwatch-agent-linux"
#  platform   = "Linux"
#  uri        = "s3://${var.aws_s3_bucket_object}/files/amazon-cloudwatch-agent-linux.yml"
#  version    = "1.0.0"
#  kms_key_id = data.aws_kms_key.image_builder.arn
#
#  depends_on = [
#    aws_s3_bucket_object.cw_agent_upload
#  ]
#}
resource "aws_imagebuilder_infrastructure_configuration" "headnode" {
  description           = "Simple infrastructure configuration"
  instance_profile_name = var.ec2_iam_role_name
  instance_types        = ["t2.micro"]
  key_pair              = var.aws_key_pair_name
  name                  = "amazon-linux-infr"
  security_group_ids    = [data.aws_security_group.headnode.id]

  subnet_id                     = data.aws_subnet.headnode.id
  terminate_instance_on_failure = true

  logging {
    s3_logs {
      s3_bucket_name = var.aws_s3_log_bucket
      s3_key_prefix  = "image-builder"
    }
  }

  tags = {
    Name = "amazon-linux-infr"
  }
}
resource "aws_imagebuilder_distribution_configuration" "headnode" {
  name = "local-distribution"

  distribution {
    ami_distribution_configuration {
      ami_tags = {
        Project = "IT"
      }

      name = "amzn-linux-{{ imagebuilder:buildDate }}"

      launch_permission {
        user_ids = ["309956199498"]
      }
    }
    region = var.aws_region
  }
}
resource "aws_imagebuilder_component" "fvcom" {
  data = yamlencode({
    phases = [{
      name = "build"
      steps = [{
        action = "ExecuteBash"
        inputs = {
          commands = ["echo 'model install script goes here'"]
        }
        name      = "fvcom"
        onFailure = "Continue"
      }]
    }]
    schemaVersion = 1.0
  })
  name     = "example"
  platform = "Linux"
  version  = "1.0.0"
}
