#========================= flagStatScript.sh =========================
#!/bin/sh

value=$(sed -n "s/.*\(properly paired ([0-9][0-9][0-9]*.[0-9][0-9]*\).*/\1/p" $1 | sed -n "s/.*\([0-9][0-9][0-9]*.\).*/\1/p" | sed -n "s/.$//p")

if (( $value < 90 ))
then
        exit 1
fi
