# Monitoring

Verified Access logs use OCSF 0.1 and exclude trust context to minimize identity-data exposure. AWS's documented schema identifies a denial with `activity_id: "2"`; the CloudWatch filter `{ $.activity_id = "2" }` publishes `Security/VerifiedAccess/VerifiedAccessDeniedRequests`.

Alarms notify `verified-access-security-alerts` for:

- `UnHealthyHostCount >= 1` for two consecutive minutes.
- ALB-generated 5XX above the configurable threshold.
- Target-generated 5XX above the configurable threshold.
- Verified Access denials above the configurable five-minute threshold.

Confirm the SNS subscription email before expecting notifications. During incident response, inspect decision/status fields and request metadata, but do not enable trust-context logging casually. If the OCSF log version is changed, validate the metric filter against a real denied event before relying on it.
