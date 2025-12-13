#!/usr/bin/env python
"""
Django Registration Database Save Test Script
==============================================
هذا السكريبت يختبر حفظ البيانات في قاعدة البيانات خطوة بخطوة

الاستخدام:
1. ضع هذا الملف في نفس مجلد manage.py
2. شغّل: python test_django_registration.py
"""

import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'your_project_name.settings')
# ⚠️ غيّر 'your_project_name' إلى اسم مشروعك الفعلي

try:
    django.setup()
except Exception as e:
    print(f"❌ خطأ في تحميل Django: {e}")
    print("\n💡 تأكد من:")
    print("   1. تشغيل السكريبت من نفس مجلد manage.py")
    print("   2. تعديل اسم المشروع في السطر 15")
    sys.exit(1)

from safechild_app.models import Parent

print("=" * 70)
print("🔍 اختبار حفظ البيانات في قاعدة البيانات")
print("=" * 70)

# Test 1: Check database connection
print("\n📊 الاختبار 1: الاتصال بقاعدة البيانات")
print("-" * 70)
try:
    count = Parent.objects.count()
    print(f"✅ الاتصال ناجح! عدد المستخدمين الحاليين: {count}")
except Exception as e:
    print(f"❌ فشل الاتصال: {e}")
    sys.exit(1)

# Test 2: Create user using create_user method
print("\n📊 الاختبار 2: إنشاء مستخدم باستخدام create_user")
print("-" * 70)

test_email = "test_user_123@example.com"

# Delete if exists
Parent.objects.filter(email=test_email).delete()
print(f"🗑️  حذف المستخدم السابق (إن وُجد): {test_email}")

try:
    print(f"\n⏳ محاولة إنشاء مستخدم: {test_email}")
    
    parent = Parent.objects.create_user(
        email=test_email,
        password="TestPassword123",
        name="Test User",
        phone_number="0501234567"
    )
    
    print(f"✅ تم إنشاء المستخدم!")
    print(f"   - ID: {parent.id}")
    print(f"   - Email: {parent.email}")
    print(f"   - Name: {parent.name}")
    print(f"   - Phone: {parent.phone_number}")
    print(f"   - Active: {parent.is_active}")
    print(f"   - Has password: {bool(parent.password)}")
    
except Exception as e:
    print(f"❌ فشل إنشاء المستخدم: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Test 3: Verify user was saved to database
print("\n📊 الاختبار 3: التحقق من حفظ المستخدم في قاعدة البيانات")
print("-" * 70)

try:
    saved_parent = Parent.objects.get(email=test_email)
    print(f"✅ المستخدم موجود في قاعدة البيانات!")
    print(f"   - ID: {saved_parent.id}")
    print(f"   - Email: {saved_parent.email}")
    print(f"   - Name: {saved_parent.name}")
    
except Parent.DoesNotExist:
    print(f"❌ المستخدم غير موجود في قاعدة البيانات!")
    print("\n🔍 هذه مشكلة خطيرة - المستخدم تم إنشاؤه لكن لم يُحفظ!")
    sys.exit(1)

# Test 4: Test password
print("\n📊 الاختبار 4: اختبار تشفير كلمة المرور")
print("-" * 70)

if saved_parent.check_password("TestPassword123"):
    print("✅ كلمة المرور مشفّرة بشكل صحيح!")
else:
    print("❌ مشكلة في تشفير كلمة المرور!")

# Test 5: List all users
print("\n📊 الاختبار 5: عرض جميع المستخدمين في قاعدة البيانات")
print("-" * 70)

all_parents = Parent.objects.all()
print(f"📋 إجمالي المستخدمين: {all_parents.count()}\n")

for idx, p in enumerate(all_parents, 1):
    print(f"{idx}. ID: {p.id} | Email: {p.email} | Name: {p.name}")

# Test 6: Test with serializer (if exists)
print("\n📊 الاختبار 6: اختبار باستخدام Serializer")
print("-" * 70)

try:
    from safechild_app.serializers import RegisterSerializer
    
    test_data = {
        'email': 'serializer_test@example.com',
        'password': 'SerializerTest123',
        'name': 'Serializer Test',
        'phone_number': '0509876543'
    }
    
    # Delete if exists
    Parent.objects.filter(email=test_data['email']).delete()
    
    serializer = RegisterSerializer(data=test_data)
    
    if serializer.is_valid():
        print("✅ البيانات صحيحة (Validation passed)")
        
        try:
            parent = serializer.save()
            print(f"✅ تم حفظ المستخدم عبر Serializer!")
            print(f"   - ID: {parent.id}")
            print(f"   - Email: {parent.email}")
            
            # Verify it's in database
            if Parent.objects.filter(email=test_data['email']).exists():
                print("✅ المستخدم موجود في قاعدة البيانات!")
            else:
                print("❌ المستخدم غير موجود في قاعدة البيانات!")
                
        except Exception as e:
            print(f"❌ خطأ أثناء حفظ Serializer: {e}")
            import traceback
            traceback.print_exc()
    else:
        print(f"❌ البيانات غير صحيحة: {serializer.errors}")
        
except ImportError:
    print("⚠️  RegisterSerializer غير موجود - تخطي هذا الاختبار")

# Final summary
print("\n" + "=" * 70)
print("📊 ملخص النتائج")
print("=" * 70)

final_count = Parent.objects.count()
print(f"✅ إجمالي المستخدمين في قاعدة البيانات: {final_count}")

if final_count > 0:
    print("\n✅ قاعدة البيانات تعمل بشكل صحيح!")
    print("   المشكلة قد تكون في:")
    print("   1. كود View (register_view)")
    print("   2. عدم استدعاء serializer.save()")
    print("   3. استثناء يحدث ولا يظهر في الـ response")
else:
    print("\n❌ قاعدة البيانات لا تحفظ البيانات!")
    print("   تحقق من:")
    print("   1. Database file permissions")
    print("   2. Migrations applied correctly")
    print("   3. Model configuration")

print("\n" + "=" * 70)
print("انتهى الاختبار")
print("=" * 70)
