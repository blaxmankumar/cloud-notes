# Access flow

1. The user opens `https://secure.lax-man.in`.
2. External DNS resolves its CNAME to the Verified Access endpoint hostname.
3. Verified Access checks for an authenticated session.
4. IAM Identity Center authenticates the user in `us-east-1`.
5. Identity Center trust data becomes `context.idc` for Cedar evaluation.
6. The group policy requires `email.verified == true` and either the configured corporate domain or an exact approved email allowlist match.
7. The endpoint policy requires the configured immutable group UUID in `context.idc.groups`.
8. Both permits must match; otherwise the request is denied before the application.
9. An allowed request leaves the Verified Access endpoint security group for the internal ALB on HTTP 80.
10. The ALB forwards only to a healthy EC2 target on port 8000.
11. Nginx serves React and proxies API, health, and identity routes to Node on the private Docker network.
12. Verified Access records the decision in CloudWatch Logs. Denials increment the security metric.

The backend is not a substitute authorization boundary. The `x-amzn-ava-user-context` header is inspected only for display/debugging and raw JWTs are never returned or logged.
