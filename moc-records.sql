-- منصة المسارات الوطنية — سجلات المستفيدين والتدقيق
-- الصق هذا الملف كاملاً في Supabase > SQL Editor ثم اضغط Run (مرة واحدة، بعد moc-setup.sql).
-- في الأسفل يظهر جدول بحسابات فريق التدقيق وكلمات مرورها (تظهر مرة واحدة فقط — انسخه واحفظه).
-- آمن لإعادة التشغيل (لا يغيّر كلمة مرور حساب موجود)، ولا يمس جداول الصحة المدرسية.

-- 1) جدول السجلات (مقفل: لا يقرؤه الزوار)
create table if not exists public.moc_records (
  id uuid primary key default gen_random_uuid(),
  center text not null,
  pathway text not null check (pathway in ('dm','lip','ob','bp','br')),
  day date not null,
  nid text not null check (nid ~ '^[12][0-9]{9}$'),
  phone text check (phone is null or phone ~ '^05[0-9]{8}$'),
  mawid boolean,
  platform boolean,
  raqeem boolean,
  audit text check (audit is null or audit in ('match','age','diag','recent')),
  audit_by uuid,
  audit_at timestamptz,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.moc_records add column if not exists audit_name text;
create index if not exists moc_records_cpd on public.moc_records (center, pathway, day);
create index if not exists moc_records_pa on public.moc_records (pathway, audit);
alter table public.moc_records enable row level security;

create or replace function public.moc_role() returns text language sql stable as
$$ select coalesce(auth.jwt()->'app_metadata'->>'role','') $$;
create or replace function public.moc_center() returns text language sql stable as
$$ select coalesce(auth.jwt()->'app_metadata'->>'center','') $$;

-- 2) الصلاحيات
-- القراءة: المشرف وفريق التدقيق يرون الكل، ومدير المركز يرى سجلات مركزه فقط
drop policy if exists moc_rec_read on public.moc_records;
create policy moc_rec_read on public.moc_records for select to authenticated
  using (public.moc_role() in ('owner','moc_auditor')
     or (public.moc_role() = 'moc_manager' and center = public.moc_center()));
-- الإضافة: مدير المركز لمركزه فقط، والمشرف للكل
drop policy if exists moc_rec_ins on public.moc_records;
create policy moc_rec_ins on public.moc_records for insert to authenticated
  with check (public.moc_role() = 'owner'
     or (public.moc_role() = 'moc_manager' and center = public.moc_center()));
-- التعديل: المشرف وفريق التدقيق للكل، ومدير المركز لسجلات مركزه التي لم تُدقق بعد
drop policy if exists moc_rec_upd on public.moc_records;
create policy moc_rec_upd on public.moc_records for update to authenticated
  using (public.moc_role() in ('owner','moc_auditor')
     or (public.moc_role() = 'moc_manager' and center = public.moc_center() and audit is null))
  with check (public.moc_role() in ('owner','moc_auditor')
     or (public.moc_role() = 'moc_manager' and center = public.moc_center()));
-- الحذف: المشرف وفريق التدقيق لأي سجل، ومدير المركز لسجلات مركزه التي لم تُدقق بعد
drop policy if exists moc_rec_del on public.moc_records;
create policy moc_rec_del on public.moc_records for delete to authenticated
  using (public.moc_role() in ('owner','moc_auditor')
     or (public.moc_role() = 'moc_manager' and center = public.moc_center() and audit is null));

-- التدقيق لا يُعدّله إلا فريق التدقيق أو المشرف، ويُسجَّل من دقق ومتى
create or replace function public.moc_rec_guard() returns trigger language plpgsql as $$
begin
  if public.moc_role() not in ('owner','moc_auditor') then
    if tg_op = 'INSERT' then
      new.audit := null; new.audit_by := null; new.audit_at := null; new.audit_name := null;
    else
      new.audit := old.audit; new.audit_by := old.audit_by; new.audit_at := old.audit_at; new.audit_name := old.audit_name;
      new.center := old.center; new.pathway := old.pathway;
    end if;
  elsif tg_op = 'UPDATE' and new.audit is distinct from old.audit then
    new.audit_by := auth.uid(); new.audit_at := now();
    new.audit_name := case when public.moc_role() = 'owner' then 'مشرف القطاع'
                           else coalesce(auth.jwt()->'user_metadata'->>'username', 'فريق التدقيق') end;
  end if;
  if public.moc_role() = 'moc_auditor' and tg_op = 'UPDATE' then
    new.nid := old.nid; new.phone := old.phone; new.day := old.day;
    new.mawid := old.mawid; new.platform := old.platform; new.raqeem := old.raqeem;
  end if;
  if tg_op = 'INSERT' then new.created_by := auth.uid(); end if;
  new.updated_at := now();
  return new;
end $$;
drop trigger if exists moc_rec_guard on public.moc_records;
create trigger moc_rec_guard before insert or update on public.moc_records
  for each row execute function public.moc_rec_guard();

revoke all on public.moc_records from anon;
grant select, insert, update, delete on public.moc_records to authenticated;

-- 3) أعداد عامة بدون أي بيانات شخصية (تظهر في المنصة للجميع)
create or replace view public.moc_counts as
  select center, pathway, day,
    count(*)::int as n,
    (count(*) filter (where audit = 'match'))::int as matched,
    (count(*) filter (where audit is not null and audit <> 'match'))::int as unmatched,
    (count(*) filter (where audit is null))::int as pending,
    (count(*) filter (where mawid and platform and raqeem))::int as complete
  from public.moc_records
  group by center, pathway, day;
grant select on public.moc_counts to anon, authenticated;

notify pgrst, 'reload schema';

-- 4) حسابات فريق التدقيق (الدخول من المنصة باختيار «فريق التدقيق» + اسم المستخدم + كلمة المرور)
-- حذف الحسابات المؤقتة السابقة (moc-audit1..3) إن وُجدت
delete from auth.identities where user_id in (select id from auth.users where email like 'moc-audit_@sh-north.example');
delete from auth.users where email like 'moc-audit_@sh-north.example';

create temp table if not exists moc_audit_creds(username text, password text);
truncate moc_audit_creds;
do $$
declare
  users text[] := array['FAlzhavi','amfaqeeh','aaboeash'];
  alpha text := 'abcdefghjkmnpqrstuvwxyz23456789';
  i int; j int; em text; pw text; uid uuid;
begin
  for i in 1..array_length(users,1) loop
    em := lower(users[i])||'@audit.sh-north.example';
    if exists (select 1 from auth.users where email = em) then
      insert into moc_audit_creds values (users[i], '(موجود مسبقاً - لم تتغير)');
      continue;
    end if;
    pw := '';
    for j in 1..10 loop
      pw := pw || substr(alpha, (get_byte(extensions.gen_random_bytes(1),0) % length(alpha))+1, 1);
    end loop;
    uid := gen_random_uuid();
    insert into auth.users (instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,
        raw_app_meta_data,raw_user_meta_data,created_at,updated_at,
        confirmation_token,recovery_token,email_change_token_new,email_change)
      values ('00000000-0000-0000-0000-000000000000',uid,'authenticated','authenticated',em,
        extensions.crypt(pw, extensions.gen_salt('bf')),now(),
        jsonb_build_object('provider','email','providers',jsonb_build_array('email'),'role','moc_auditor'),
        jsonb_build_object('username',users[i]),now(),now(),'','','','');
    insert into auth.identities (id,user_id,provider_id,identity_data,provider,last_sign_in_at,created_at,updated_at)
      values (gen_random_uuid(),uid,uid::text,jsonb_build_object('sub',uid::text,'email',em,'email_verified',true),'email',now(),now(),now());
    insert into moc_audit_creds values (users[i], pw);
  end loop;
end $$;

select username as "اسم المستخدم", password as "كلمة المرور" from moc_audit_creds order by username;
