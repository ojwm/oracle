# Vulnerabilities

## Page submit

Pages can be submitted from the browser console, even when steps have been taken to secure or hide the submit button, by using the APEX submit command with the name of the request.

```text
> APEX.SUBMIT('SAVE')
```

### Mitigation

When using a button to handle page submission directly, rather than through a dynamic action, ensure that any server-side conditions and authorisation schemas on the button are replicated on the submit process and any subsequent branches.
