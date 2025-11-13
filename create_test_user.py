#!/usr/bin/env python3
"""Script para crear usuario de prueba con hash correcto"""
from passlib.hash import bcrypt
import pymysql

# Generar hash
password = "password123"
hashed = bcrypt.hash(password)
print(f"Hash generado: {hashed}")

# Conectar a la base de datos
try:
    connection = pymysql.connect(
        host='mysql_db',
        user='user',
        password='password',
        database='user_db'
    )
    
    with connection.cursor() as cursor:
        # Eliminar usuario existente si existe
        cursor.execute("DELETE FROM users WHERE email = %s", ('test@owlboard.com',))
        
        # Insertar nuevo usuario
        sql = "INSERT INTO users (email, hashed_password, full_name, is_active) VALUES (%s, %s, %s, %s)"
        cursor.execute(sql, ('test@owlboard.com', hashed, 'Test User', 1))
        
        connection.commit()
        print(f"✅ Usuario creado exitosamente!")
        
        # Verificar
        cursor.execute("SELECT id, email, full_name, is_active FROM users WHERE email = %s", ('test@owlboard.com',))
        user = cursor.fetchone()
        print(f"   - ID: {user[0]}")
        print(f"   - Email: {user[1]}")
        print(f"   - Name: {user[2]}")
        print(f"   - Active: {user[3]}")
        
finally:
    connection.close()
