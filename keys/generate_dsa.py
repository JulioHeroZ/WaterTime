import os
import base64
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import dsa
from cryptography.exceptions import InvalidSignature

def load_private_key(key_path):
    with open(key_path, 'rb') as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None
        )
    return private_key

def generate_dsa_signature(installer_path, private_key_path):
    # Carrega a chave privada existente
    private_key = load_private_key(private_key_path)
    
    # Lê o arquivo do instalador
    with open(installer_path, 'rb') as f:
        data = f.read()
    
    # Gera a assinatura
    signature = private_key.sign(
        data,
        hashes.SHA1()
    )
    
    # Converte para base64
    signature_b64 = base64.b64encode(signature).decode('utf-8')
    
    return signature_b64

def load_public_key(key_path):
    with open(key_path, 'rb') as key_file:
        public_key = serialization.load_pem_public_key(
            key_file.read()
        )
    return public_key

def verify_signature(installer_path, public_key_path, signature_b64):
    # Carrega a chave pública
    public_key = load_public_key(public_key_path)
    
    # Lê o arquivo do instalador
    with open(installer_path, 'rb') as f:
        data = f.read()
    
    # Decodifica a assinatura de base64
    signature = base64.b64decode(signature_b64)
    
    try:
        # Verifica a assinatura
        public_key.verify(
            signature,
            data,
            hashes.SHA1()
        )
        return True
    except InvalidSignature:
        return False

# Caminhos dos arquivos
installer_path = r"C:\Users\071444\Documents\Projetos\WaterTime\watertime\Output\watertime-1.3.0+1-windows-setup.exe"
private_key_path = r"C:\Users\071444\Documents\Projetos\WaterTime\watertime\keys\dsa_priv.pem"
public_key_path = r"C:\Users\071444\Documents\Projetos\WaterTime\watertime\keys\dsa_pub.pem"

try:
    signature = generate_dsa_signature(installer_path, private_key_path)
    print("\nDSA Signature:")
    print(signature)

    is_valid = verify_signature(installer_path, public_key_path, signature)
    if is_valid:
        print("A assinatura é válida!")
    else:
        print("A assinatura é inválida!")
except Exception as e:
    print(f"Erro ao gerar ou verificar assinatura: {str(e)}")