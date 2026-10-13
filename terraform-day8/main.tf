terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "devops-learner-tfstate-67891"
    key            = "day8/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Application  = "cloud-platform"
      Environment  = "dev"
      Owner        = "divya"
      CostCenter   = "cc-1001"
      BusinessUnit = "platform"
    }
  }
}

# ---------- Part A: Secrets Manager ----------

resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!#%*-_"
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "day8/db-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db.result
  })
}

# ---------- Part B: CloudWatch monitoring ----------

# The camera recording: where the app writes its logs
resource "aws_cloudwatch_log_group" "app" {
  name              = "/platform/day8-app"
  retention_in_days = 7
}

# The person counting: every log line containing ERROR becomes a count of 1
resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "day8-error-count"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "Platform/Day8"
    value     = "1"
  }
}

# The phone line: where alerts get sent
resource "aws_sns_topic" "alerts" {
  name = "day8-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "divyakchaudhari15@gmail.com"
}

# The siren: rings when 1 or more errors appear within a minute
resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name          = "day8-app-errors"
  alarm_description   = "Fires when the app logs an ERROR"
  namespace           = "Platform/Day8"
  metric_name         = "ErrorCount"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}