# K Planner

A backward-planning calendar and checklist for NIH career development (K) award
applicants at UNC. Answer four questions — institute, mechanism (K08 or K23),
new vs. resubmission, and NIH due date — and it generates a month-by-month
calendar working back from the deadline, an interactive checklist, and an `.ics`
export. Everything runs client-side; there is no backend and no data leaves the
browser (checkmarks are stored locally on the device).

It's a Progressive Web App: self-hosted fonts, a manifest, and a service worker
mean it installs to a phone home screen and works offline once loaded.

---

## Deploying to Carolina CloudApps

CloudApps runs Red Hat OpenShift. This is a static site, so the simplest path is
OpenShift's **httpd source-to-image (S2I) builder** pointed at this Git repo — no
Dockerfile, no container registry. You need an active CloudApps subscription and
the `oc` CLI (download it from the "?" menu in the web console, or from Red Hat).

### One-time: get the code into a Git repo

Push this folder to any Git host CloudApps can reach (github.com, or UNC GitLab
at `gitlab.its.unc.edu`). The static files must stay at the repo **root** —
that's what the httpd builder serves.

### Option A — command line (recommended)

```bash
# 1. Log in. Grab the exact command (with a token) from the CloudApps web
#    console: click your name, top right, then "Copy login command".
oc login --token=sha256~... --server=https://api.cloudapps.unc.edu:6443

# 2. Create a project (skip if you already have one). Use your own name.
oc new-project k-planner --display-name="K Planner"

# 3. Build + deploy straight from the repo using the httpd builder image.
#    Replace the URL with your repo. --context-dir is only needed if the
#    files are NOT at the repo root.
oc new-app httpd:2.4-ubi9~https://github.com/ezeitler09/k-planner.git \
  --name=k-planner

# 4. Watch the build. First build pulls the builder image, so give it a minute.
oc logs -f bc/k-planner

# 5. Expose it at a public HTTPS URL (edge-terminated, HTTP redirects to HTTPS).
oc create route edge k-planner --service=k-planner --insecure-policy=Redirect

# 6. Get the URL.
oc get route k-planner -o jsonpath='{.spec.host}{"\n"}'
```

That host will be something like `k-planner-<project>.apps.cloudapps.unc.edu`.
A service worker needs HTTPS — the edge route provides it, so installability and
offline both work on the deployed URL (they won't over plain `http://`).

**Shipping an update later:** push to the repo, then `oc start-build k-planner`.
When you change any cached file, bump the `CACHE` constant in `sw.js` (e.g.
`kplanner-v1` → `kplanner-v2`) so returning visitors pull the new version instead
of the cached one.

### Option B — web console, no CLI

1. Sign in at <https://console.apps.cloudapps.unc.edu/>.
2. Switch to the **Developer** perspective, select or create your project.
3. **+Add** → **Import from Git**.
4. Paste the repo URL. Under *Builder Image* choose **httpd**. Leave the context
   dir as `/`.
5. Under *Advanced options* make sure a **Route** is created (checked by default).
6. **Create.** Watch the build in *Topology*; when the pod goes blue, click the
   route arrow to open the live URL.

### Option C — Dockerfile fallback

If you'd rather serve with nginx (or the httpd builder isn't available), this
repo includes an OpenShift-safe `Dockerfile` (runs as a random non-root UID,
listens on 8080) and an `nginx.conf`. Deploy it with:

```bash
oc new-app https://github.com/ezeitler09/k-planner.git --strategy=docker --name=k-planner
oc create route edge k-planner --service=k-planner --insecure-policy=Redirect
```

---

## What's in here

| Path                     | Purpose                                              |
|--------------------------|------------------------------------------------------|
| `index.html`             | The whole app — markup, styles, and logic in one file |
| `fonts/`                 | Self-hosted IBM Plex (woff2 + woff), 9 weights        |
| `icons/`                 | PWA icons (192, 512, maskable)                        |
| `manifest.webmanifest`   | PWA manifest                                          |
| `sw.js`                  | Service worker — offline app shell, cache-versioned   |
| `Dockerfile`, `nginx.conf` | Fallback container path only                        |

## Notes / next steps

- The "before you write" milestones (D−180, D−120) are reasonable defaults, not
  UNC policy. Adjust the offsets in the `milestones()` function in `index.html`
  if your office's rhythm differs.
- Internal lead times (sponsored programs packet, Cayuse) are user-editable in
  the form and default to 10 and 5 days.
- Federal holidays aren't handled — only weekends. A milestone landing on a
  holiday won't shift. Worth adding if this gets real use.
- No analytics, no tracking, no external calls once loaded.
