# Updates

- Added a Win64 VCL VAT Submitter with local setup, sign-in, obligations, nine-box returns, liabilities, payments, and user administration.
- Stored organisation, users, obligations, returns, and HMRC tokens in a local SQLite database through Aurelius.
- Submitted returns through the HMRC VAT client in `HMRC-MTD-VAT`, including test-scenario headers and desktop fraud-prevention headers.
- In debug builds, prefill the local sign-in as John Doe (`John` / `testing`) and the HMRC sandbox client id, client secret, and server token from the original test-mode VAT client.
- In debug builds, keep the application on the HMRC sandbox, store its data separately, create the organisation and VAT number through the sandbox test-user API, show the sandbox user id and password when granting access, and ask for a Gov-Test-Scenario before obligations, returns, liabilities, and payments.
- Opened the main window after first-run setup by creating it before the setup dialog and signing in the administrator that setup just created.
- Rebuilt the screens as design-time VCL forms and frames, with the obligations, return, liabilities, settings, and users pages hosted by the main form instead of being created in code.
- When HMRC has no access token, or the token has expired, start the HMRC sign-in window and retry the obligations, return, liabilities, or payments request.
- Sign in to HMRC on a page that keeps the sandbox user id and password beside the browser, and exchange the permission code directly so the token request has a real address.
- Treat a data lock as free when the process that created it is no longer running, and offer to clear a lock that another running copy still holds.
- Open the VAT return only from a selected obligation, and keep a fulfilled or submitted return read-only.
