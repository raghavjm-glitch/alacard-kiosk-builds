# Alacard kiosk — builds

Finished, ready-to-run builds of the Alacard kiosk app.

**There is no source code here.** That lives in a private repository. This one
exists so a kiosk in a shop can fetch its own updates without a password stored
on the machine, which is the safer arrangement of the two: a password sitting in
a shop can be read by whoever reaches the machine.

The app is not useful on its own. It asks for a kiosk code on first run and does
nothing without one.

## For a kiosk

Nothing to read here. A kiosk fetches what it needs by itself, twice a day.

## Setting a new machine up

One command, on the machine:

```bash
curl -fsSL https://raw.githubusercontent.com/raghavjm-glitch/alacard-kiosk-builds/main/bootstrap.sh | bash
```

## What is in a release

- `alacard-<version>.tar.gz` — the compiled app
- `alacard-kiosk-<version>.zip` — the same app plus the setup scripts, for a
  machine being set up for the first time
- `test.json` / `all.json` — which build each channel is on

Two channels on purpose. **Nothing reaches `all` until it has served real
customers on the test kiosk.** `all` means 25 shops at once, and there is no
undo at that scale.
