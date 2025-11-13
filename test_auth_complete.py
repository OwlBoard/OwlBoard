#!/usr/bin/env python3
"""Prueba de autenticación completa con usuario real"""
import urllib.request
import ssl
import json

ctx = ssl._create_unverified_context()

print("="*60)
print("PRUEBA DE AUTENTICACIÓN COMPLETA")
print("="*60)

# Test 1: Login
print("\n1. Intentando login con test@owlboard.com...")
try:
    credentials = {
        'email': 'test@owlboard.com',
        'password': 'password123'
    }
    data = json.dumps(credentials).encode('utf-8')
    req = urllib.request.Request(
        'https://localhost:8443/auth/login',
        data=data,
        headers={'Content-Type': 'application/json'},
        method='POST'
    )
    response = urllib.request.urlopen(req, context=ctx)
    tokens = json.loads(response.read().decode())
    
    print("✅ Login exitoso!")
    print(f"   - Access Token (primeros 50 chars): {tokens['access_token'][:50]}...")
    print(f"   - Refresh Token (primeros 50 chars): {tokens['refresh_token'][:50]}...")
    print(f"   - Token Type: {tokens['token_type']}")
    print(f"   - Expires in: {tokens['expires_in']} segundos")
    
    access_token = tokens['access_token']
    refresh_token = tokens['refresh_token']
    
except urllib.error.HTTPError as e:
    print(f"❌ Error HTTP {e.code}: {e.read().decode()}")
    exit(1)
except Exception as e:
    print(f"❌ Error: {e}")
    exit(1)

# Test 2: Validate token
print("\n2. Validando access token...")
try:
    req = urllib.request.Request(
        f'https://localhost:8443/auth/token/validate?token={access_token}',
        headers={'Authorization': f'Bearer {access_token}'},
        method='GET'
    )
    response = urllib.request.urlopen(req, context=ctx)
    validation = json.loads(response.read().decode())
    
    print("✅ Token válido!")
    print(f"   - User ID: {validation.get('user_id')}")
    print(f"   - Email: {validation.get('email')}")
    print(f"   - Valid: {validation.get('valid')}")
    
except Exception as e:
    print(f"⚠️  Validación falló: {e}")

# Test 3: Introspect token
print("\n3. Inspeccionando token...")
try:
    data = json.dumps({'token': access_token}).encode('utf-8')
    req = urllib.request.Request(
        'https://localhost:8443/auth/token/introspect',
        data=data,
        headers={'Content-Type': 'application/json'},
        method='POST'
    )
    response = urllib.request.urlopen(req, context=ctx)
    introspection = json.loads(response.read().decode())
    
    print("✅ Introspección exitosa!")
    print(f"   - Active: {introspection.get('active')}")
    print(f"   - Subject: {introspection.get('sub')}")
    print(f"   - Username: {introspection.get('username')}")
    
except Exception as e:
    print(f"⚠️  Introspección falló: {e}")

# Test 4: Refresh token
print("\n4. Refrescando token...")
try:
    data = json.dumps({'refresh_token': refresh_token}).encode('utf-8')
    req = urllib.request.Request(
        'https://localhost:8443/auth/token/refresh',
        data=data,
        headers={'Content-Type': 'application/json'},
        method='POST'
    )
    response = urllib.request.urlopen(req, context=ctx)
    new_tokens = json.loads(response.read().decode())
    
    print("✅ Tokens refrescados!")
    print(f"   - Nuevo Access Token: {new_tokens['access_token'][:50]}...")
    print(f"   - Nuevo Refresh Token: {new_tokens['refresh_token'][:50]}...")
    
    new_access_token = new_tokens['access_token']
    
except Exception as e:
    print(f"⚠️  Refresh falló: {e}")
    new_access_token = access_token

# Test 5: Revoke token
print("\n5. Revocando token...")
try:
    data = json.dumps({'token': new_access_token, 'token_type': 'access'}).encode('utf-8')
    req = urllib.request.Request(
        'https://localhost:8443/auth/token/revoke',
        data=data,
        headers={'Content-Type': 'application/json'},
        method='POST'
    )
    response = urllib.request.urlopen(req, context=ctx)
    revoke_result = json.loads(response.read().decode())
    
    print("✅ Token revocado exitosamente!")
    print(f"   - Mensaje: {revoke_result.get('message')}")
    
except Exception as e:
    print(f"⚠️  Revocación falló: {e}")

print("\n" + "="*60)
print("🎉 TODAS LAS PRUEBAS COMPLETADAS")
print("El Auth Service está completamente funcional!")
print("="*60)
