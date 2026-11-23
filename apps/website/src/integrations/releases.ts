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
      sizeBytes: 8_216_148,
      sizeLabel: site.fallbackDmgSize,
    },
    checksumsUrl: site.checksumsUrl,
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

export async function fetchLatestRelease(): Promise<ReleaseInfo> {
  const now = Date.now()
  if (cached && cached.expiresAt > now) {
    return cached.value
  }

  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), 3500)
  try {
    const response = await fetch('https://api.github.com/repos/blinks44/rebind/releases/latest', {
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
