import pefile
import hashlib
import base64
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding, dsa
from cryptography.hazmat.primitives import serialization

def extract_and_verify_signature(exe_path, public_key_path):
    try:
        # Carrega a chave pública
        with open(public_key_path, 'rb') as key_file:
            public_key = serialization.load_pem_public_key(key_file.read())
        
        pe = pefile.PE(exe_path)
        
        if hasattr(pe, 'DIRECTORY_ENTRY_SECURITY'):
            for cert in pe.DIRECTORY_ENTRY_SECURITY:
                print("\nInformações da Assinatura Digital:")
                print(f"Tamanho: {cert.dwLength}")
                print(f"Revisão: {cert.wRevision}")
                print(f"Tipo de Certificado: {cert.wCertificateType}")
                
                # Extrai o hash SHA1 do executável
                sha1 = hashlib.sha1()
                with open(exe_path, 'rb') as f:
                    sha1.update(f.read())
                print(f"\nSHA1 do arquivo: {sha1.hexdigest()}")
                
                # Tenta verificar a assinatura
                try:
                    public_key.verify(
                        cert.Certificate,
                        sha1.digest(),
                        hashes.SHA1()
                    )
                    print("\nAssinatura DSA válida!")
                except Exception as e:
                    print(f"\nErro na verificação da assinatura: {e}")
                
                return cert.Certificate
        else:
            print("\nArquivo não está assinado com DSA.")
            return None
            
    except Exception as e:
        print(f"\nErro ao processar arquivo: {e}")
        return None

# Caminhos dos arquivos
exe_path = r"C:\Users\071444\Documents\Projetos\WaterTime\watertime\Output\watertime-1.3.0+1-windows-setup_signed.exe"
public_key_path = r"C:\Users\071444\Documents\Projetos\WaterTime\watertime\keys\dsa_pub.pem"

# Executa a verificação
signature = extract_and_verify_signature(exe_path, public_key_path)

if signature:
    print("\nAssinatura base64:")
    print(base64.b64encode(signature).decode('utf-8'))