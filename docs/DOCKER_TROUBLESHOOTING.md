# Docker Troubleshooting

This guide helps resolve common Docker deployment issues with ups.

## Quick Docker Test

```bash
# 1. Generate a master key
MASTER_KEY=$(openssl rand -hex 16)
echo "Generated master key: $MASTER_KEY"

# 2. Test the container (will fail without proper credentials, but should start)
docker run --rm -p 3000:80 \
  -e RAILS_MASTER_KEY=$MASTER_KEY \
  -e HOST_URL=http://localhost:3000 \
  ghcr.io/codenamev/ups:main

# 3. Should see Rails attempting to boot (will fail on credentials)
```

## Common Issues

### ❌ "no matching manifest for linux/amd64"

**Problem:** You're using the broken `latest` tag.

**Solution:** Use the `main` tag instead:
```bash
docker pull ghcr.io/codenamev/ups:main
```

**Root cause:** The latest tag was built without proper multi-architecture support. This is a known issue tracked in the launch plan.

### ❌ "AEAD authentication tag verification failed"

**Problem:** Invalid or missing `RAILS_MASTER_KEY`.

**Solutions:**

1. **For testing:** Generate a dummy key and accept that credentials won't work:
   ```bash
   RAILS_MASTER_KEY=$(openssl rand -hex 16)
   ```

2. **For production:** Set up proper credentials:
   ```bash
   # Generate new credentials
   bundle exec rails credentials:edit
   # Use the master key from config/master.key
   ```

### ❌ "Container exits immediately"

**Problem:** Missing required environment variables.

**Solution:** Ensure you have at minimum:
```bash
docker run -e RAILS_MASTER_KEY=your-key \
           -e HOST_URL=https://your-domain.com \
           ghcr.io/codenamev/ups:main
```

### ❌ "Health check failing"

**Problem:** Container not responding on expected port.

**Solution:** The container serves on port 80 internally (via Thruster):
```bash
docker run -p 3000:80 ghcr.io/codenamev/ups:main
#              ^^^^ Map to internal port 80, not 3000
```

## Verified Working Setup

The following setup has been tested and works:

```yaml
# docker-compose.yml (use the one in the repo)
services:
  ups:
    image: ghcr.io/codenamev/ups:main  # NOT latest!
    ports:
      - "3000:80"  # Internal port 80
    environment:
      - RAILS_MASTER_KEY=${RAILS_MASTER_KEY}
      - HOST_URL=${HOST_URL}
    volumes:
      - ups_storage:/rails/storage
```

## Docker Image Status

| Tag | Status | Architecture | Notes |
|-----|---------|-------------|-------|
| `main` | ✅ Working | amd64, arm64 | Use this for now |
| `latest` | ❌ Broken | arm64 only | Avoid until fixed |
| `v*` | ⚠️ Untested | Should be multi-arch | Use semantic versions when available |

## Production Checklist

Before deploying ups with Docker in production:

- [ ] Use `main` tag (not `latest`)
- [ ] Generate proper `RAILS_MASTER_KEY` with `rails credentials:edit`
- [ ] Set correct `HOST_URL` for your domain
- [ ] Mount persistent volume for `/rails/storage`
- [ ] Set up reverse proxy with SSL (see Caddyfile.example)
- [ ] Configure email delivery in Rails credentials
- [ ] Test the complete flow: signup → create status page → trigger incident

## Getting Help

If these solutions don't work:

1. Check the [GitHub Issues](https://github.com/codenamev/ups/issues)
2. Share your docker logs: `docker logs <container-name>`
3. Include your environment (OS, Docker version, architecture)

---

*Last updated: March 10, 2026*