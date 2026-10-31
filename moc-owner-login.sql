-- منصة المسارات الوطنية — تغيير اسم المستخدم وكلمة المرور لحساب مشرف القطاع
-- حساب واحد للمشرف في المنصتين: منصة المسارات الوطنية ومنصة الصحة المدرسية (نفس اسم المستخدم وكلمة المرور).
-- 1) في السطر 8 استبدل كلمة USERNAME باسم المستخدم (حروف إنجليزية وأرقام)، وفي السطر 9 استبدل PASSWORD بكلمة المرور (8 أحرف على الأقل). اترك علامتي ' ' كما هما.
-- 2) اضغط Run. تظهر في الأسفل رسالة بالبريد الجديد للدخول.
-- 3) امسح كلمة المرور من المحرر بعد التشغيل ولا تحفظ الاستعلام (Snippet).
do $$
declare
  new_user text := 'USERNAME';
  new_pw   text := 'PASSWORD';
  em text; n int; uid uuid;
begin
  if new_user = 'USERNAME' or new_pw = 'PASSWORD' then raise exception 'اكتب اسم المستخدم وكلمة المرور الجديدة أولاً.'; end if;
  if new_user !~ '^[A-Za-z0-9._-]{3,30}$' then raise exception 'اسم المستخدم: حروف إنجليزية وأرقام فقط (من 3 إلى 30).'; end if;
  if length(new_pw) < 8 then raise exception 'كلمة المرور يجب أن تكون 8 أحرف على الأقل.'; end if;
  select count(*) into n from auth.users where raw_app_meta_data->>'role' = 'owner';
  if n <> 1 then raise exception 'يوجد % حساب بصلاحية المشرف — لم يُغيَّر شيء، راجعني.', n; end if;
  select id into uid from auth.users where raw_app_meta_data->>'role' = 'owner';
  em := lower(new_user) || '@admin.sh-north.example';
  if exists (select 1 from auth.users where email = em and id <> uid) then raise exception 'اسم المستخدم مستخدم لحساب آخر.'; end if;
  update auth.users set
      email = em,
      encrypted_password = extensions.crypt(new_pw, extensions.gen_salt('bf')),
      email_confirmed_at = coalesce(email_confirmed_at, now()),
      email_change = '', email_change_token_new = '',
      raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object('username', new_user),
      updated_at = now()
    where id = uid;
  update auth.identities set identity_data = identity_data || jsonb_build_object('email', em), updated_at = now()
    where user_id = uid and provider = 'email';
  raise notice 'تم. الدخول في المنصتين باسم المستخدم: %', new_user;
end $$;
select raw_user_meta_data->>'username' as "اسم مستخدم المشرف" from auth.users where raw_app_meta_data->>'role' = 'owner';
