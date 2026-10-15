import { Upload } from 'tus-js-client'
import { supabase } from './supabase'

const bucket = 'portfolio-images'
const resumableThreshold = 6 * 1024 * 1024

export async function uploadPortfolioImage(
  file: File,
  path: string,
  onProgress: (percent: number) => void = () => undefined,
): Promise<{ error: string | null }> {
  if (!supabase) return { error: 'Supabase is not configured in this deployment.' }

  if (file.size <= resumableThreshold) {
    try {
      const { error } = await supabase.storage.from(bucket).upload(path, file, {
        contentType: file.type,
        upsert: false,
      })
      return { error: error ? describeError(error) : null }
    } catch (error) {
      return { error: describeError(error) }
    }
  }

  try {
    const { data: { session }, error } = await supabase.auth.getSession()
    if (error) return { error: describeError(error) }
    if (!session) return { error: 'Your admin session expired. Sign in again and retry.' }

    const endpoint = `${import.meta.env.VITE_SUPABASE_URL.replace(/\/$/, '')}/storage/v1/upload/resumable`
    await new Promise<void>((resolve, reject) => {
      const upload = new Upload(file, {
        endpoint,
        retryDelays: [0, 3000, 5000, 10000, 20000],
        headers: {
          apikey: import.meta.env.VITE_SUPABASE_ANON_KEY,
          authorization: `Bearer ${session.access_token}`,
          'x-upsert': 'false',
        },
        uploadDataDuringCreation: true,
        removeFingerprintOnSuccess: true,
        chunkSize: resumableThreshold,
        metadata: {
          bucketName: bucket,
          objectName: path,
          contentType: file.type,
          cacheControl: '3600',
        },
        onError: reject,
        onProgress: (uploaded, total) => onProgress(Math.round((uploaded / total) * 100)),
        onSuccess: () => resolve(),
      })

      void upload.findPreviousUploads().then((previous) => {
        if (previous.length) upload.resumeFromPreviousUpload(previous[0])
        upload.start()
      }).catch(reject)
    })
    return { error: null }
  } catch (error) {
    return { error: describeError(error) }
  }
}

function describeError(error: unknown): string {
  if (!(error instanceof Error)) return 'The upload failed. Please retry.'
  const status = 'status' in error && typeof error.status === 'number' ? ` (HTTP ${error.status})` : ''
  const message = error.message || 'The upload failed.'
  if (message.toLowerCase().includes('failed to fetch')) {
    return 'The browser could not reach Supabase Storage. Check your connection, disable any request-blocking browser extensions, and retry.'
  }
  if (status.includes('403') || message.toLowerCase().includes('row-level security')) {
    return 'Supabase rejected this upload. Confirm your user is listed in public.admin_users and the Storage upload policies from the migration are installed.'
  }
  return `${message}${status}`
}
