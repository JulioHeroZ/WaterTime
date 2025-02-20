import os
import base64
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import dsa

def load_private_key(key_path):
    with open(key_path, 'rb') as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None
        )
    return private_key

def sign_installer(installer_path, private_key_path):
    # Carrega a chave privada
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

# Caminhos dos arquivos
installer_path = r"C:\Users\071444\Documents\Projetos\WaterTime\watertime\Output\watertime-1.3.0+1-windows-setup.exe"
private_key_path = r"C:\Users\071444\Documents\Projetos\WaterTime\watertime\keys\dsa_priv.pem"

try:
    signature = sign_installer(installer_path, private_key_path)
    print("\nAssinatura DSA gerada:")
    print(signature)
    
    # Opcional: Salvar a assinatura em um arquivo
    with open('last_signature.txt', 'w') as f:
        f.write(signature)
        
except Exception as e:
    print(f"Erro ao gerar assinatura: {str(e)}")