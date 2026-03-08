# This fulfills the Identity Federation requirement
resource "aws_iam_saml_provider" "entra_id" {
  name                   = "AzureEntraID"
  saml_metadata_document = file("AWS-Federation-Project-270511957.xml") # PLACE YOUR XML FILE IN PROJECT ROOT
}

# IAM Role that Azure users will assume
resource "aws_iam_role" "devops_engineer" {
  name = "EntraID-DevOpsEngineer"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithSAML"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_saml_provider.entra_id.arn
        }
        Condition = {
          StringEquals = {
            "SAML:aud" = "https://signin.aws.amazon.com/saml"
          }
        }
      }
    ]
  })
}

# Policy attachment for the federated role
resource "aws_iam_role_policy_attachment" "devops_engineer_admin" {
  role       = aws_iam_role.devops_engineer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# The Read-Only Role for auditors

resource "aws_iam_role" "read_only_auditor" {
  name               = "ReadOnlyAuditorRole"
  assume_role_policy = aws_iam_role.devops_engineer.assume_role_policy
}

# The Policy attached to the role (Replaces the inline_policy block)
resource "aws_iam_role_policy" "read_only_policy" {
  name = "ReadOnlyAccessPolicy"
  role = aws_iam_role.read_only_auditor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["ec2:Describe*", "ecs:Describe*", "cloudwatch:Get*", "s3:Get*", "s3:List*"]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}