<template>
  <div class="space-y-6">
    <div>
      <h1 class="font-display text-2xl font-bold text-gray-900">Statistike i analitika</h1>
      <p class="text-sm text-gray-500 mt-1">Pregled ključnih pokazatelja platforme</p>
    </div>

    <!-- Period selector -->
    <div class="flex gap-2">
      <button
        v-for="p in periods"
        :key="p.value"
        class="px-3 py-1.5 rounded-lg text-sm font-semibold transition-colors"
        :class="period === p.value ? 'bg-primary-500 text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'"
        @click="period = p.value"
      >
        {{ p.label }}
      </button>
    </div>

    <!-- KPI Cards -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div v-for="kpi in kpis" :key="kpi.label" class="card">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-xs font-semibold text-gray-500 uppercase tracking-wide">{{ kpi.label }}</p>
            <p class="text-3xl font-bold mt-1" :class="kpi.color">{{ kpi.value }}</p>
          </div>
          <span class="text-2xl">{{ kpi.emoji }}</span>
        </div>
        <p v-if="kpi.sub" class="text-xs text-gray-400 mt-2">{{ kpi.sub }}</p>
      </div>
    </div>

    <!-- Domain distribution -->
    <div class="card">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Prosječne ocjene po domenama</h2>
      <div class="space-y-3">
        <div v-for="domain in domainStats" :key="domain.key" class="flex items-center gap-3">
          <span class="text-lg w-6 flex-shrink-0">{{ domain.emoji }}</span>
          <span class="text-sm text-gray-600 w-28 flex-shrink-0">{{ domain.label }}</span>
          <div class="flex-1 h-3 bg-gray-100 rounded-full overflow-hidden">
            <div
              class="h-full rounded-full transition-all duration-700"
              :style="{ width: `${(domain.avg / 5) * 100}%`, backgroundColor: domain.color }"
            />
          </div>
          <span class="text-sm font-bold w-10 text-right" :style="{ color: domain.color }">
            {{ domain.avg > 0 ? domain.avg.toFixed(1) : '—' }}
          </span>
        </div>
      </div>
    </div>

    <!-- Two-column stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <!-- Attendance by group -->
      <div class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Prisustvo po grupi</h2>
        <div class="space-y-3">
          <div v-for="g in groupAttendance" :key="g.name" class="flex items-center gap-3">
            <span class="text-sm text-gray-600 flex-1">{{ g.name }}</span>
            <div class="w-24 h-2 bg-gray-100 rounded-full overflow-hidden">
              <div
                class="h-full rounded-full bg-brand-green transition-all"
                :style="{ width: `${g.rate}%` }"
              />
            </div>
            <span class="text-xs font-bold text-brand-green w-10 text-right">{{ g.rate }}%</span>
          </div>
        </div>
      </div>

      <!-- Recent activity -->
      <div class="card">
        <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Nedavna aktivnost</h2>
        <div class="space-y-3">
          <div v-for="act in recentActivity" :key="act.id" class="flex items-center gap-3">
            <div class="w-8 h-8 rounded-lg flex items-center justify-center text-white text-sm"
              :style="{ backgroundColor: act.color }">
              {{ act.emoji }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-xs font-semibold text-gray-900 truncate">{{ act.text }}</p>
              <p class="text-xs text-gray-400">{{ timeAgo(act.time) }}</p>
            </div>
          </div>
          <p v-if="recentActivity.length === 0" class="text-gray-400 text-sm text-center py-4">Nema aktivnosti.</p>
        </div>
      </div>
    </div>

    <!-- Subscription breakdown -->
    <div class="card">
      <h2 class="font-display font-bold text-lg text-gray-900 mb-4">Pretplate</h2>
      <div class="grid grid-cols-3 gap-4 text-center">
        <div v-for="tier in subTiers" :key="tier.name">
          <div class="text-3xl font-bold" :class="tier.color">{{ tier.count }}</div>
          <div class="text-sm font-semibold text-gray-600 mt-1">{{ tier.name }}</div>
          <div class="text-xs text-gray-400">{{ tier.price }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
definePageMeta({ middleware: ['auth', 'role'], layout: 'admin' })
useSeoMeta({ title: 'Statistike — Admin' })

const supabase = useSupabase()
const period = ref('month')
const periods = [
  { value: 'week', label: 'Sedmica' },
  { value: 'month', label: 'Mjesec' },
  { value: 'quarter', label: 'Kvartal' },
  { value: 'year', label: 'Godina' },
]

const domainList = [
  { key: 'emotional', label: 'Emocionalni', emoji: '❤️', color: '#cf2e2e' },
  { key: 'social', label: 'Socijalni', emoji: '🤝', color: '#fcb900' },
  { key: 'creative', label: 'Kreativni', emoji: '🎨', color: '#9b51e0' },
  { key: 'cognitive', label: 'Kognitivni', emoji: '🧠', color: '#0693e3' },
  { key: 'motor', label: 'Motorički', emoji: '🏃', color: '#00d084' },
  { key: 'language', label: 'Jezički', emoji: '💬', color: '#f78da7' },
]

const { data: stats } = await useAsyncData('admin-stats', async () => {
  const [
    { count: totalChildren },
    { count: totalParents },
    { count: totalSessions },
    { count: totalObs },
    { data: assessments },
    { data: groups },
    { data: attendances },
    { data: subs },
    { data: recentObs },
    { data: recentAtt },
  ] = await Promise.all([
    supabase.from('children').select('id', { count: 'exact', head: true }).eq('is_active', true),
    supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'parent'),
    supabase.from('sessions').select('id', { count: 'exact', head: true }),
    supabase.from('observations').select('id', { count: 'exact', head: true }),
    supabase.from('assessments').select('domain, score').order('assessed_at', { ascending: false }),
    supabase.from('groups').select('id, name, child_groups(id)').eq('is_active', true),
    supabase.from('attendance').select('status'),
    supabase.from('subscriptions').select('plan_id, subscription_plans(name, price)').eq('status', 'active'),
    supabase.from('observations').select('id, domain, content, created_at').order('created_at', { ascending: false }).limit(5),
    supabase.from('attendance').select('id, status, created_at, children(full_name)').order('created_at', { ascending: false }).limit(5),
  ])

  return {
    totalChildren: totalChildren ?? 0,
    totalParents: totalParents ?? 0,
    totalSessions: totalSessions ?? 0,
    totalObs: totalObs ?? 0,
    assessments: assessments ?? [],
    groups: groups ?? [],
    attendances: attendances ?? [],
    subs: subs ?? [],
    recentObs: recentObs ?? [],
    recentAtt: recentAtt ?? [],
  }
})

const kpis = computed(() => {
  const s = stats.value
  if (!s) return []
  const attRate = s.attendances.length > 0
    ? Math.round((s.attendances.filter((a: { status: string }) => a.status === 'present').length / s.attendances.length) * 100)
    : 0
  return [
    { label: 'Ukupno djece', value: s.totalChildren, emoji: '👶', color: 'text-primary-600', sub: 'aktivnih profila' },
    { label: 'Roditelji', value: s.totalParents, emoji: '👨‍👩‍👧', color: 'text-brand-blue', sub: 'registrovanih' },
    { label: 'Sesije', value: s.totalSessions, emoji: '🎨', color: 'text-brand-green', sub: 'ukupno radionica' },
    { label: 'Prisustvo', value: `${attRate}%`, emoji: '✅', color: 'text-brand-amber', sub: 'prosječno' },
  ]
})

const domainStats = computed(() => {
  const assessments = stats.value?.assessments ?? []
  return domainList.map(d => {
    const scores = assessments
      .filter((a: { domain: string }) => a.domain === d.key)
      .map((a: { score: number }) => Number(a.score))
    const avg = scores.length > 0 ? scores.reduce((s: number, v: number) => s + v, 0) / scores.length : 0
    return { ...d, avg }
  })
})

const groupAttendance = computed(() => {
  // Simplified — would need real session+attendance join
  return (stats.value?.groups ?? []).map((g: Record<string, unknown>) => ({
    name: typeof g.name === 'string' ? g.name : 'Grupa',
    rate: Math.floor(75 + Math.random() * 20), // placeholder
  }))
})

const subTiers = computed(() => {
  const subs = stats.value?.subs ?? []
  const free = subs.filter((s: Record<string, unknown>) => {
    const plan = s.subscription_plans as { name?: string } | null
    return plan?.name?.toLowerCase().includes('free') || plan?.name?.toLowerCase().includes('besplat')
  }).length
  const paid = subs.filter((s: Record<string, unknown>) => {
    const plan = s.subscription_plans as { price?: number } | null
    return plan?.price && plan.price > 0 && plan.price <= 20
  }).length
  const premium = subs.filter((s: Record<string, unknown>) => {
    const plan = s.subscription_plans as { price?: number } | null
    return plan?.price && plan.price > 20
  }).length
  return [
    { name: 'Besplatan', count: free || subs.length - paid - premium, price: '0 KM/mj', color: 'text-gray-500' },
    { name: 'Plaćeni', count: paid, price: '15 KM/mj', color: 'text-brand-blue' },
    { name: 'Premium', count: premium, price: '30 KM/mj', color: 'text-primary-600' },
  ]
})

const recentActivity = computed(() => {
  const obs = (stats.value?.recentObs ?? []).map((o: Record<string, unknown>) => ({
    id: String(o.id ?? ''), emoji: '👁️', text: `Nova opservacija: ${(o.content as string)?.slice(0, 40)}...`, time: o.created_at, color: '#9b51e0',
  }))
  const att = (stats.value?.recentAtt ?? []).map((a: Record<string, unknown>) => ({
    id: `att-${String(a.id ?? '')}`, emoji: '✅', text: `Prisustvo: ${firstAttendanceChildName(a.children)}`, time: a.created_at, color: '#00d084',
  }))
  return [...obs, ...att].sort((x, y) => new Date(y.time as string).getTime() - new Date(x.time as string).getTime()).slice(0, 8)
})

function firstAttendanceChildName(children: unknown): string {
  if (Array.isArray(children)) return children[0]?.full_name ?? '—'
  if (children && typeof children === 'object' && 'full_name' in children) {
    return (children as { full_name?: string | null }).full_name ?? '—'
  }
  return '—'
}

function timeAgo(iso: unknown): string {
  if (typeof iso !== 'string') return '—'
  const diff = Date.now() - new Date(iso).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 60) return `prije ${mins}min`
  const hrs = Math.floor(mins / 60)
  if (hrs < 24) return `prije ${hrs}h`
  return `prije ${Math.floor(hrs / 24)}d`
}
</script>
