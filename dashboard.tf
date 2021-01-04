# https://github.com/strvcom/terraform-aws-fargate/blob/master/metrics/basic-dashboard.json
locals {
  dashboard = {
    start          = "-PT4H"
    end            = null
    periodOverride = null
    widgets = [
      {
        x = 6
        y = 0

        type = "metric"
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCountPerTarget", "TargetGroup", "target_group_name"]
          ]
          view     = "timeSeries"
          stacked  = false
          region   = var.aws_region
          title    = "RequestsPerTarget (1 min sum)"
          period   = 60
          stat     = "Sum"
          liveData = false
        }
      }
    ]
  }
}



resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_body = jsonencode(local.dashboard)
  dashboard_name = "${var.environment}-${var.prefix}${var.app_name}${var.suffix}"
}
