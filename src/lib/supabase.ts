import { createClient } from '@supabase/supabase-js'
export const configured = Boolean(import.meta.env.VITE_SUPABASE_URL && import.meta.env.VITE_SUPABASE_ANON_KEY)
export const supabase = configured ? createClient(import.meta.env.VITE_SUPABASE_URL!, import.meta.env.VITE_SUPABASE_ANON_KEY!, { auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true } }) : null

export type Category = { id: string; name: string; slug: string; description: string | null; display_order: number; is_visible: boolean }
export type Photo = { id: string; title: string | null; caption: string | null; description: string | null; storage_path: string; category_id: string | null; display_order: number; is_published: boolean; is_featured: boolean; created_at: string }
export type Settings = { hero_photo_id: string | null; hero_position: string; biography: string; email: string; phone: string; location: string; instagram: string; website: string; overlay_strength: number }
export const defaultSettings: Settings = { hero_photo_id: null, hero_position: 'center center', biography: '', email: '', phone: '', location: '', instagram: '', website: '', overlay_strength: 0 }
export const imageUrl = (path: string) => supabase?.storage.from('portfolio-images').getPublicUrl(path).data.publicUrl ?? ''
