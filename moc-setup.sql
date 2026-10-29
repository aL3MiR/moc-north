-- منصة المسارات الوطنية لنموذج الرعاية الصحية — القطاع الشمالي
-- إعداد قاعدة البيانات + حساب لكل مركز + نقل الإعدادات الحالية
-- الصق هذا الملف كاملاً في Supabase > SQL Editor ثم اضغط Run.
-- في الأسفل يظهر جدول بأسماء المراكز وكلمات المرور (تظهر مرة واحدة فقط — انسخه واحفظه).
-- آمن لإعادة التشغيل: لا يغيّر كلمات مرور الحسابات الموجودة، ولا يمس جداول الصحة المدرسية.

-- 1) الجداول
create table if not exists public.moc_config (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
create table if not exists public.moc_entries (
  id text primary key,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.moc_config enable row level security;
alter table public.moc_entries enable row level security;

-- 2) الصلاحيات
-- الإعدادات: قراءة للجميع، وتعديل للمشرف فقط
drop policy if exists moc_config_read on public.moc_config;
drop policy if exists moc_config_owner on public.moc_config;
create policy moc_config_read on public.moc_config for select using (true);
create policy moc_config_owner on public.moc_config for all
  using ((auth.jwt()->'app_metadata'->>'role') = 'owner')
  with check ((auth.jwt()->'app_metadata'->>'role') = 'owner');

-- الرصد اليومي: قراءة للجميع، والمشرف يعدّل الكل، ومدير المركز يعدّل سجلات مركزه فقط (لا يحذف)
drop policy if exists moc_entries_read on public.moc_entries;
drop policy if exists moc_entries_owner on public.moc_entries;
drop policy if exists moc_entries_mgr_ins on public.moc_entries;
drop policy if exists moc_entries_mgr_upd on public.moc_entries;
create policy moc_entries_read on public.moc_entries for select using (true);
create policy moc_entries_owner on public.moc_entries for all
  using ((auth.jwt()->'app_metadata'->>'role') = 'owner')
  with check ((auth.jwt()->'app_metadata'->>'role') = 'owner');
create policy moc_entries_mgr_ins on public.moc_entries for insert to authenticated
  with check ((auth.jwt()->'app_metadata'->>'role') = 'moc_manager'
    and split_part(id,'_',1) = (auth.jwt()->'app_metadata'->>'center')
    and (data->>'center') = (auth.jwt()->'app_metadata'->>'center'));
create policy moc_entries_mgr_upd on public.moc_entries for update to authenticated
  using ((auth.jwt()->'app_metadata'->>'role') = 'moc_manager'
    and split_part(id,'_',1) = (auth.jwt()->'app_metadata'->>'center'))
  with check ((auth.jwt()->'app_metadata'->>'role') = 'moc_manager'
    and split_part(id,'_',1) = (auth.jwt()->'app_metadata'->>'center')
    and (data->>'center') = (auth.jwt()->'app_metadata'->>'center'));

grant usage on schema public to anon, authenticated;
grant select on public.moc_config, public.moc_entries to anon, authenticated;
grant insert, update, delete on public.moc_config, public.moc_entries to authenticated;

-- 3) نقل الإعدادات الحالية (المراكز، المدراء، المستهدفات، الرصيد الافتتاحي حتى 2026-09-29)
insert into public.moc_config (id, data) values ('main', $cfg${"baseline": {"c01": {"bp": 53, "br": 0, "col": {"req": 11, "res": 11}, "dm": 112, "lip": 91, "ob": 52}, "c02": {"bp": 95, "br": 0, "col": {"req": 5, "res": 5}, "dm": 39, "lip": 32, "ob": 97}, "c03": {"bp": 50, "br": 0, "col": {"req": 4, "res": 4}, "dm": 45, "lip": 37, "ob": 49}, "c04": {"bp": 23, "br": 0, "col": {"req": 3, "res": 3}, "dm": 10, "lip": 5, "ob": 23}, "c05": {"bp": 28, "br": 0, "col": {"req": 4, "res": 4}, "dm": 25, "lip": 24, "ob": 27}, "c06": {"bp": 36, "br": 0, "col": {"req": 9, "res": 9}, "dm": 39, "lip": 23, "ob": 37}, "c07": {"bp": 175, "br": 0, "col": {"req": 10, "res": 10}, "dm": 59, "lip": 63, "ob": 180}, "c08": {"bp": 22, "br": 0, "col": {"req": 4, "res": 4}, "dm": 15, "lip": 12, "ob": 24}, "c09": {"bp": 32, "br": 0, "col": {"req": 3, "res": 3}, "dm": 17, "lip": 13, "ob": 31}, "c10": {"bp": 30, "br": 0, "col": {"req": 1, "res": 1}, "dm": 26, "lip": 24, "ob": 31}, "c11": {"bp": 55, "br": 0, "col": {"req": 3, "res": 3}, "dm": 61, "lip": 38, "ob": 56}, "c12": {"bp": 36, "br": 0, "col": {"req": 5, "res": 5}, "dm": 17, "lip": 22, "ob": 36}, "c13": {"bp": 120, "br": 0, "col": {"req": 6, "res": 6}, "dm": 52, "lip": 30, "ob": 130}, "c14": {"bp": 273, "br": 0, "col": {"req": 11, "res": 11}, "dm": 68, "lip": 61, "ob": 272}, "c15": {"bp": 58, "br": 0, "col": {"req": 3, "res": 3}, "dm": 29, "lip": 21, "ob": 58}, "c16": {"bp": 339, "br": 0, "col": {"req": 16, "res": 16}, "dm": 94, "lip": 74, "ob": 354}, "c17": {"bp": 69, "br": 0, "col": {"req": 4, "res": 4}, "dm": 42, "lip": 23, "ob": 71}, "c18": {"bp": 348, "br": 0, "col": {"req": 11, "res": 11}, "dm": 134, "lip": 124, "ob": 351}, "c19": {"bp": 41, "br": 0, "col": {"req": 2, "res": 2}, "dm": 38, "lip": 38, "ob": 42}, "c20": {"bp": 78, "br": 0, "col": {"req": 4, "res": 4}, "dm": 50, "lip": 56, "ob": 80}, "c21": {"bp": 91, "br": 0, "col": {"req": 7, "res": 7}, "dm": 20, "lip": 28, "ob": 95}, "c22": {"bp": 36, "br": 0, "col": {"req": 9, "res": 9}, "dm": 44, "lip": 39, "ob": 38}, "c23": {"bp": 16, "br": 0, "col": {"req": 1, "res": 1}, "dm": 13, "lip": 8, "ob": 16}, "c24": {"bp": 66, "br": 0, "col": {"req": 5, "res": 5}, "dm": 19, "lip": 28, "ob": 68}, "c25": {"bp": 0, "br": 0, "col": {"req": 0, "res": 0}, "dm": 0, "lip": 0, "ob": 0}}, "baselineDate": "2026-09-29", "centers": [{"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c01", "manager": "مها علي القاسمي", "name": "السلامة العليا"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c02", "manager": "محمد حسن أبو جميلة", "name": "الدرب"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c03", "manager": "أحمد محمد نهاري", "name": "الحقو"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c04", "manager": "محمد علي العزي", "name": "الجبل الأسود"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c05", "manager": "جابر علي عبادي", "name": "الخلاوية"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c06", "manager": "موسى محمد النجادي", "name": "الريث"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c07", "manager": "مقبول محمد عقيلي", "name": "الشقيق"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c08", "manager": "أحمد محمد حقوي", "name": "القوام"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c09", "manager": "إبراهيم أحمد عتودي", "name": "عتود"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c10", "manager": "عبدالله أحمد صروي", "name": "قايم الدش"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c11", "manager": "إبراهيم علي بحري", "name": "المطعن"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c12", "manager": "محمد عبده عتودي", "name": "منشبة"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c13", "manager": "مضحي إبراهيم شلعي", "name": "مسلية"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c14", "manager": "عبدالرحمن أبوخويجة", "name": "أبو السداد"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c15", "manager": "ماجد أحمد طفيان", "name": "السادة"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c16", "manager": "موسى إبراهيم عويدي", "name": "بيش"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c17", "manager": "يحيى مصطفى سويد", "name": "بيش الجنوبي"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c18", "manager": "رجاء إبراهيم الأخرش", "name": "العالية"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c19", "manager": "حسين يحيى حامضي", "name": "العشة"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c20", "manager": "حصة محي عميش", "name": "المحلة"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c21", "manager": "محمد أحمد زين الدين", "name": "قرية بيش"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c22", "manager": "موسى محمد النعمي", "name": "القطيحة"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c23", "manager": "مشهور عرار شماخي", "name": "مقزع"}, {"active": {"bp": true, "br": true, "col": true, "dm": true, "lip": true, "ob": true}, "id": "c24", "manager": "جدح يحيى السلمي", "name": "عمود"}, {"active": {"bp": false, "br": true, "col": false, "dm": false, "lip": false, "ob": false}, "id": "c25", "manager": "جابر حقوي", "name": "القهر"}], "director": "شريفة حمود حكمي", "reminder": {"active": true, "lines": ["التحويل على نظام موعد.", "إضافة البيانات لمنصة المسار بعد التحويل على نظام موعد.", "التركيز على جودة الإحالة.", "إدخال الأوردر في رقيم.", "عدم تحويل السيدة في حالة الرفض أو دون علمها.", "التحويل الورقي في حالة تعطل النظام."], "title": "تذكير بتحويل الماموجرام للأسبوع الثالث من شهر أكتوبر — يوم الخميس"}, "salama": {"full": "مركز الرعاية الصحية الأولية بالسلامة العليا", "id": "c01", "ministry": "38100"}, "targets": {"c01": {"bp": 226, "br": 10, "col": 10, "dm": 104, "lip": 70, "ob": 226}, "c02": {"bp": 236, "br": 10, "col": 10, "dm": 109, "lip": 73, "ob": 236}, "c03": {"bp": 184, "br": 6, "col": 6, "dm": 85, "lip": 57, "ob": 184}, "c04": {"bp": 13, "br": 1, "col": 2, "dm": 6, "lip": 4, "ob": 13}, "c05": {"bp": 70, "br": 3, "col": 4, "dm": 32, "lip": 22, "ob": 70}, "c06": {"bp": 85, "br": 6, "col": 6, "dm": 39, "lip": 26, "ob": 85}, "c07": {"bp": 281, "br": 10, "col": 10, "dm": 129, "lip": 86, "ob": 281}, "c08": {"bp": 66, "br": 3, "col": 4, "dm": 30, "lip": 20, "ob": 66}, "c09": {"bp": 77, "br": 4, "col": 4, "dm": 35, "lip": 24, "ob": 77}, "c10": {"bp": 83, "br": 3, "col": 5, "dm": 38, "lip": 25, "ob": 83}, "c11": {"bp": 145, "br": 6, "col": 6, "dm": 67, "lip": 45, "ob": 145}, "c12": {"bp": 189, "br": 8, "col": 6, "dm": 87, "lip": 58, "ob": 189}, "c13": {"bp": 142, "br": 6, "col": 6, "dm": 65, "lip": 44, "ob": 142}, "c14": {"bp": 244, "br": 10, "col": 10, "dm": 112, "lip": 75, "ob": 244}, "c15": {"bp": 47, "br": 4, "col": 4, "dm": 22, "lip": 14, "ob": 47}, "c16": {"bp": 212, "br": 10, "col": 14, "dm": 97, "lip": 65, "ob": 212}, "c17": {"bp": 131, "br": 8, "col": 6, "dm": 60, "lip": 40, "ob": 131}, "c18": {"bp": 402, "br": 10, "col": 14, "dm": 185, "lip": 124, "ob": 402}, "c19": {"bp": 147, "br": 6, "col": 6, "dm": 68, "lip": 45, "ob": 147}, "c20": {"bp": 148, "br": 9, "col": 6, "dm": 68, "lip": 46, "ob": 148}, "c21": {"bp": 114, "br": 4, "col": 6, "dm": 53, "lip": 35, "ob": 114}, "c22": {"bp": 93, "br": 6, "col": 6, "dm": 43, "lip": 29, "ob": 93}, "c23": {"bp": 85, "br": 4, "col": 5, "dm": 39, "lip": 26, "ob": 85}, "c24": {"bp": 76, "br": 2, "col": 4, "dm": 35, "lip": 23, "ob": 76}, "c25": {"bp": null, "br": 1, "col": null, "dm": null, "lip": null, "ob": null}}}$cfg$::jsonb)
  on conflict (id) do nothing;

notify pgrst, 'reload schema';

-- 4) حساب لكل مركز (المستخدم: moc-cXX@sh-north.example — الدخول من المنصة باختيار اسم المركز + كلمة المرور)
create temp table if not exists moc_creds(cid text, center text, password text);
truncate moc_creds;
do $$
declare
  ids text[] := array['c01','c02','c03','c04','c05','c06','c07','c08','c09','c10','c11','c12','c13','c14','c15','c16','c17','c18','c19','c20','c21','c22','c23','c24','c25'];
  names text[] := array['السلامة العليا','الدرب','الحقو','الجبل الأسود','الخلاوية','الريث','الشقيق','القوام','عتود','قايم الدش','المطعن','منشبة','مسلية','أبو السداد','السادة','بيش','بيش الجنوبي','العالية','العشة','المحلة','قرية بيش','القطيحة','مقزع','عمود','القهر'];
  alpha text := 'abcdefghjkmnpqrstuvwxyz23456789';
  i int; j int; em text; pw text; uid uuid;
begin
  for i in 1..array_length(ids,1) loop
    em := 'moc-'||ids[i]||'@sh-north.example';
    if exists (select 1 from auth.users where email = em) then
      insert into moc_creds values (ids[i], names[i], '(موجود مسبقاً - لم تتغير)');
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
        jsonb_build_object('provider','email','providers',jsonb_build_array('email'),'role','moc_manager','center',ids[i]),
        jsonb_build_object('center_name',names[i]),now(),now(),'','','','');
    insert into auth.identities (id,user_id,provider_id,identity_data,provider,last_sign_in_at,created_at,updated_at)
      values (gen_random_uuid(),uid,uid::text,jsonb_build_object('sub',uid::text,'email',em,'email_verified',true),'email',now(),now(),now());
    insert into moc_creds values (ids[i], names[i], pw);
  end loop;
end $$;

-- 5) النتيجة: انسخها واحفظها وسلّم كل مدير كلمة مرور مركزه
select cid as "الرمز", center as "المركز", password as "كلمة المرور" from moc_creds order by cid;
