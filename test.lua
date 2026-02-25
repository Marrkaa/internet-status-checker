local rc = os.execute("ping -c 1 -q 8.8.8.8")

if rc then
    rc = rc / 256
end

print("Real return code:", rc)