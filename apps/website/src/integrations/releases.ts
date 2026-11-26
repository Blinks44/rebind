import { createServerFn } from '@tanstack/react-start'
import { site } from '@/config/site'

export interface ReleaseAsset {
  name: string
  url: string
  sizeBytes: number
  sizeLabel: string
}

export interface ReleaseInfo {
  version: string
  tag: string
  releaseUrl: string
  dmg: ReleaseAsset
  checksumsUrl: string
}

interface GitHubReleasePayload {
  tag_name?: string
  html_url?: string
  assets?: Array<{
    name?: string
    browser_download_url?: string
    size?: number
  }>
}

const CACHE_TTL_MS = 10 * 60 * 1000
let cached: { value: ReleaseInfo; expiresAt: number } | null = null

export function formatBytesMb(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return site.fallbackDmgSize
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

export function fallbackReleaseInfo(): ReleaseInfo {
  return {
    version: site.fallbackVersion,
    tag: `v${site.fallbackVersion}`,
    releaseUrl: `${site.releases}/latest`,
    dmg: {
      name: 'Rebind.dmg',
      url: site.downloadUrl,
      sizeBytes: 8_490_489,
      sizeLabel: site.fallbackDmgSize,
    },
    checksumsUrl: site.checksumsUrl,
  }
}

export function extractTagFromLocation(location: string | null | undefined): string | null {
  if (!location) return null
  const match = location.match(/\/releases\/tag\/([^/?#]+)/)
  if (!match?.[1]) return null
  try {
    return decodeURIComponent(match[1])
  } catch {
    return match[1]
  }
}

export function releaseInfoForTag(rawTag: string): ReleaseInfo {
  const fallback = fallbackReleaseInfo()
  const tag = rawTag.trim()
  const version = tag.replace(/^v/i, '') || site.fallbackVersion
  const normalizedTag = tag || `v${version}`
  const encodedTag = encodeURIComponent(normalizedTag)
  const base = `${site.releases}/download/${encodedTag}`

  return {
    version,
    tag: normalizedTag,
    releaseUrl: `${site.releases}/tag/${encodedTag}`,
    dmg: {
      name: 'Rebind.dmg',
      url: `${base}/Rebind.dmg`,
      sizeBytes: fallback.dmg.sizeBytes,
      sizeLabel: fallback.dmg.sizeLabel,
    },
    checksumsUrl: `${base}/SHA256SUMS.txt`,
  }
}

export function parseGitHubRelease(payload: GitHubReleasePayload): ReleaseInfo {
  const fallback = fallbackReleaseInfo()
  const rawTag = payload.tag_name?.trim()
  if (!rawTag) return fallback
  const version = rawTag.replace(/^v/i, '')
  const assets = Array.isArray(payload.assets) ? payload.assets : []
  const dmgAsset = assets.find((a) => a.name?.toLowerCase().endsWith('.dmg'))
  const checksumAsset = assets.find((a) => a.name?.toUpperCase().includes('SHA256'))

  return {
    version,
    tag: rawTag,
    releaseUrl: payload.html_url || `${site.releases}/tag/${rawTag}`,
    dmg: dmgAsset?.browser_download_url
      ? {
          name: dmgAsset.name || 'Rebind.dmg',
          url: dmgAsset.browser_download_url,
          sizeBytes: dmgAsset.size ?? fallback.dmg.sizeBytes,
          sizeLabel: formatBytesMb(dmgAsset.size ?? fallback.dmg.sizeBytes),
        }
      : fallback.dmg,
    checksumsUrl: checksumAsset?.browser_download_url || fallback.checksumsUrl,
  }
}

export async function fetchLatestRelease(
  fetcher: typeof fetch = fetch,
  now = Date.now(),
): Promise<ReleaseInfo> {
  if (cached && cached.expiresAt > now) {
    return cached.value
  }

  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), 3500)
  try {
    // Prefer the unthrottled /releases/latest redirect so shared Cloudflare
    // Workers egress IPs never trip api.github.com's 60 req/hr limit.
    const redirectResponse = await fetcher(`${site.releases}/latest`, {
      method: 'HEAD',
      redirect: 'manual',
      headers: {
        'User-Agent': 'rebind-website',
      },
      signal: controller.signal,
    })
    const redirectedTag =
      extractTagFromLocation(redirectResponse.headers?.get('location')) ??
      extractTagFromLocation(redirectResponse.url)
    if (redirectedTag) {
      const resolved = releaseInfoForTag(redirectedTag)
      cached = { value: resolved, expiresAt: now + CACHE_TTL_MS }
      return resolved
    }

    const response = await fetcher('https://api.github.com/repos/blinks44/rebind/releases/latest', {
      headers: {
        Accept: 'application/vnd.github+json',
        'User-Agent': 'rebind-website',
      },
      signal: controller.signal,
    })
    if (!response.ok) {
      throw new Error(`GitHub API returned ${response.status}`)
    }
    const payload = (await response.json()) as GitHubReleasePayload
    const parsed = parseGitHubRelease(payload)
    cached = { value: parsed, expiresAt: now + CACHE_TTL_MS }
    return parsed
  } catch {
    const fallback = fallbackReleaseInfo()
    cached = { value: fallback, expiresAt: now + 2 * 60 * 1000 }
    return fallback
  } finally {
    clearTimeout(timer)
  }
}

export function resetReleaseCache(): void {
  cached = null
}

export const getLatestRelease = createServerFn({ method: 'GET' }).handler(async () => {
  return fetchLatestRelease()
})
