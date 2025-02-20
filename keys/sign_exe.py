import os
import base64
import pefile
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import dsa
from cryptography.x509.oid import NameOID
from cryptography import x509
import datetime

def load_private_key(key_path):
    with open(key_path, 'rb') as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None
        )
        return private_key

def sign_pe_file(installer_path, private_key_path):
    # Carrega a chave privada
    private_key = load_private_key(private_key_path)
    
    # Abre o arquivo PE
    pe = pefile.PE(installer_path)
    
    # Gera o hash SHA1 do conteúdo do arquivo
    with open(installer_path, 'rb') as f:
        content = f.read()
        
    # Gera a assinatura
    signature = private_key.sign(
        content,
        hashes.SHA1()
    )
    
    # Converte para base64
    signature_b64 = base64.b64encode(signature).decode('utf-8')
    
    # Adiciona a entrada de segurança ao PE
    pe.OPTIONAL_HEADER.DATA_DIRECTORY[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_SECURITY']].VirtualAddress = len(content)
    pe.OPTIONAL_HEADER.DATA_DIRECTORY[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_SECURITY']].Size = len(signature)
    
    # Salva o arquivo assinado
    output_path = installer_path.replace('.exe', '_signed.exe')
    pe.write(output_path)
    
    # Append a assinatura ao final do arquivo
    with open(output_path, 'ab') as f:
        f.write(signature)
    
    print(f"\nArquivo assinado salvo em: {output_path}")
    return signature_b64

# Caminhos dos arquivos
installer_path = r"C:\Users\071444\Documents\Projetos\WaterTime\watertime\Output\watertime-1.3.0+1-windows-setup.exe"
private_key_path = r"C:\Users\071444\Documents\Projetos\WaterTime\watertime\keys\dsa_priv.pem"

try:
    signature = sign_pe_file(installer_path, private_key_path)
    print("\nAssinatura DSA gerada e aplicada:")
    print(signature)
    
    # Salva a assinatura em um arquivo
    with open('last_signature.txt', 'w') as f:
        f.write(signature)
        
except Exception as e:
    print(f"Erro ao assinar arquivo: {str(e)}")