-- ================================================================
-- KING · Sistema Pro — Supabase Schema v2
-- Pega TODO esto en: Supabase → SQL Editor → New query → Run
-- ================================================================

-- ----------------------------------------------------------------
-- CACCER · Control de inversión mensual
-- ----------------------------------------------------------------
create table if not exists caccer (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users on delete cascade,
  creado     timestamptz default now(),
  mes        text        not null,
  inversion  numeric     not null default 0,
  devolucion numeric     not null default 0,
  tasa       numeric     not null default 0
);
create index if not exists caccer_user_id_idx on caccer(user_id);

-- ----------------------------------------------------------------
-- VENTAS
-- ----------------------------------------------------------------
create table if not exists ventas (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null default auth.uid() references auth.users on delete cascade,
  creado   timestamptz default now(),
  fecha    date,
  cliente  text,
  producto text,
  cant     numeric default 0,
  p_unit   numeric default 0,
  desc_pct numeric default 0,
  metodo   text,
  estado   text
);
create index if not exists ventas_user_id_idx on ventas(user_id);

-- ----------------------------------------------------------------
-- COMPRAS · Gastos del negocio
-- ----------------------------------------------------------------
create table if not exists compras (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid not null default auth.uid() references auth.users on delete cascade,
  creado    timestamptz default now(),
  fecha     date,
  proveedor text,
  concepto  text,
  categoria text,
  cant      numeric default 0,
  total     numeric default 0,
  estado    text
);
create index if not exists compras_user_id_idx on compras(user_id);

-- ----------------------------------------------------------------
-- MOVIMIENTOS · Finanzas personales
-- ----------------------------------------------------------------
create table if not exists movimientos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users on delete cascade,
  creado      timestamptz default now(),
  fecha       date,
  tipo        text,
  clase       text,
  categoria   text,
  descripcion text,
  metodo      text,
  monto       numeric default 0
);
create index if not exists movimientos_user_id_idx on movimientos(user_id);

-- ----------------------------------------------------------------
-- INVENTARIO
-- ----------------------------------------------------------------
create table if not exists inventario (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid not null default auth.uid() references auth.users on delete cascade,
  creado    timestamptz default now(),
  codigo    text,
  producto  text,
  categoria text,
  stock     numeric default 0,
  stock_min numeric default 0,
  costo_u   numeric default 0,
  p_venta   numeric default 0
);
create index if not exists inventario_user_id_idx on inventario(user_id);

-- ----------------------------------------------------------------
-- CLIENTES
-- ----------------------------------------------------------------
create table if not exists clientes (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null default auth.uid() references auth.users on delete cascade,
  creado   timestamptz default now(),
  cliente  text,
  contacto text,
  ciudad   text,
  tipo     text
);
create index if not exists clientes_user_id_idx on clientes(user_id);

-- ----------------------------------------------------------------
-- DEUDAS POR COBRAR
-- ----------------------------------------------------------------
create table if not exists deudas_cobrar (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null default auth.uid() references auth.users on delete cascade,
  creado   timestamptz default now(),
  concepto text,
  fecha    date,
  vence    date,
  monto    numeric default 0,
  abonado  numeric default 0
);
create index if not exists deudas_cobrar_user_id_idx on deudas_cobrar(user_id);

-- ----------------------------------------------------------------
-- DEUDAS POR PAGAR
-- ----------------------------------------------------------------
create table if not exists deudas_pagar (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null default auth.uid() references auth.users on delete cascade,
  creado   timestamptz default now(),
  concepto text,
  fecha    date,
  vence    date,
  monto    numeric default 0,
  abonado  numeric default 0
);
create index if not exists deudas_pagar_user_id_idx on deudas_pagar(user_id);

-- ----------------------------------------------------------------
-- HOLDEO · Reposición mensual
-- ----------------------------------------------------------------
create table if not exists holdeo (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null default auth.uid() references auth.users on delete cascade,
  creado   timestamptz default now(),
  mes      text    not null,
  meta     numeric not null default 900,
  aportado numeric not null default 0
);
create index if not exists holdeo_user_id_idx on holdeo(user_id);

-- ----------------------------------------------------------------
-- HABITOS · dias = boolean[31], un elemento por día del mes
-- ----------------------------------------------------------------
create table if not exists habitos (
  id      uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  creado  timestamptz default now(),
  nombre  text    not null,
  dias    boolean[] not null default array_fill(false, array[31])
);
create index if not exists habitos_user_id_idx on habitos(user_id);

-- ----------------------------------------------------------------
-- METAS
-- ----------------------------------------------------------------
create table if not exists metas (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid not null default auth.uid() references auth.users on delete cascade,
  creado    timestamptz default now(),
  meta      text    not null,
  categoria text,
  objetivo  numeric not null default 0,
  actual    numeric not null default 0,
  fuente    text    not null default 'manual'
);
create index if not exists metas_user_id_idx on metas(user_id);

-- ----------------------------------------------------------------
-- SETTINGS · Clave-valor por usuario (presupuestoIngreso, igvRate…)
-- ----------------------------------------------------------------
create table if not exists settings (
  user_id uuid    not null default auth.uid() references auth.users on delete cascade,
  key     text    not null,
  value   jsonb,
  primary key (user_id, key)
);
create index if not exists settings_user_id_idx on settings(user_id);

-- ================================================================
-- RLS · Cada usuario ve y toca solo su propia data
-- ================================================================
do $$
declare t text;
begin
  foreach t in array array[
    'caccer','ventas','compras','movimientos','inventario','clientes',
    'deudas_cobrar','deudas_pagar','holdeo','habitos','metas','settings'
  ]
  loop
    execute format('alter table %I enable row level security;', t);
    execute format('drop policy if exists own_all on %I;', t);
    execute format(
      'create policy own_all on %I
         for all
         using     (user_id = auth.uid())
         with check (user_id = auth.uid());',
      t
    );
  end loop;
end $$;
