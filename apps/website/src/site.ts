/** Set both once the repository and the domain are public; the page adapts by itself. */
export const site = {
  /** `owner/name` on GitHub. While null, the download button is a placeholder. */
  githubRepo: null as string | null,
  /** Absolute origin without a trailing slash; enables canonical, hreflang and Open Graph URLs. */
  url: null as string | null,
}
