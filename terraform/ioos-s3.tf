resource "aws_iam_user" "noaa-ioos-users" {
  count = length(var.noaa-ioos-users)
  name  = element(var.noaa-ioos-users, count.index)
  path  = "/external-users/"
}

variable "noaa-ioos-users" {
  type    = list(string)
  default = ["OWP", "GLERL", "NOS", "CORA", "LiveOcean"]
}

resource "aws_iam_policy" "input-policy" {
  name        = "noaa-ioos_bucket_input_policy"
  path        = "/"
  description = "policy allowing noaa-ioos sources to put data into their bucket locations"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "S3:*",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::noaa-ioos/$${aws:username}"
      },
    ]
  })
}

# resource "aws_s3_bucket" "noaa-ioos" {
#   bucket = "noaa-ioos"
#   tags = {
#     Name        = "noaa-ioos"
#   }
# }

data "aws_s3_bucket" "noaa-ioos" {
  bucket = ioos-coastalsb-inputs
   tags = {
     Name        = "ioos-coastalsb-inputs"
   }
}


resource "aws_iam_group" "noaa-ioos" {
  name = "noaa-ioos"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "noaa-ioos-attach" {
  group      = aws_iam_group.noaa-ioos.name
  policy_arn = aws_iam_policy.input-policy.arn
}

resource "aws_iam_user_group_membership" "Users" {
#  user = aws_iam_user.NERFC.name
  count = length(var.noaa-ioos-users)
  user  = element(var.noaa-ioos-users, count.index)
  groups = [
    aws_iam_group.noaa-ioos.name,
  ]
}


# data "aws_iam_policy" "input-policy" {
#   name        = "noaa-ioos_bucket_input_policy"
#   path        = "/"
#   description = "policy allowing noaa-ioos sources to put data into their bucket locations"

#   # Terraform's "jsonencode" function converts a
#   # Terraform expression result to valid JSON syntax.
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "S3:*",
#         ]
#         Effect   = "Allow"
#         Resource = "arn:aws:s3:::noaa-ioos/$${aws:username}"
#       },
#     ]
#   })
# }

# data "aws_s3_bucket" "noaa-ioos" {
#   bucket = var.mount_bucket_name
#   # bucket = "noaa-ioos"

#   tags = {
#     Name        = "noaa-ioos"
#   }
# }

# data "aws_iam_group" "noaa-ioos" {
#   name = "noaa-ioos"
#   path = "/"
# }

#data "aws_iam_group_policy_attachment" "noaa-ioos-attach" {
#   group      = aws_iam_group.noaa-ioos.name
#   policy_arn = aws_iam_policy.input-policy.arn
# }

# data "aws_iam_user_group_membership" "NERFC" {
# #  user = aws_iam_user.NERFC.name
#   count = length(var.noaa-ioos-users)
#   user  = element(var.noaa-ioos-users, count.index)
#   groups = [
#     aws_iam_group.noaa-ioos.name,
#   ]
# }
