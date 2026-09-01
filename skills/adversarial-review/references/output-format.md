# Output Format -- Worked Example

## Adversarial Review

One high-severity bug, otherwise clean. Fixed in place.

---

### 🔴 High

**Race on the shared counter under concurrent requests**

`stats.count += 1` in `handler.go:88` is a non-atomic read-modify-write on a package-level variable, hit from every request goroutine. Two requests arriving within the same scheduler tick can both read the same value and one increment is lost -- under load this silently undercounts. Fixed: replaced with `atomic.AddInt64(&stats.count, 1)`.

---

### 🟠 Medium

**Retry loop has no backoff**

`retryFetch` in `client.go:41` retries immediately on failure, up to 5 times. Against a struggling upstream this turns one slow request into a burst of 5, worsening the outage it's reacting to. Left as a finding -- adding backoff changes the function's timing contract, not safe to auto-fix without a decision on max total wait.

---

**Summary:** Safe to ship -- the counter race is fixed; the retry backoff is a follow-up, not a blocker.
