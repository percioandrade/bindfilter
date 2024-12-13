# Bind Filter Script

This script helps to filter known malicious domains in Bind9 and keep config updated, preventing DNS spoofing and DNS hijacking.

---

## Features

- **Update Files**: Download the latest `blockeddomains.db` and `blocked_domain_acl.conf` files from the remote repository.
- **Run DNS Filter**: Apply the downloaded files to your Bind9 configuration.
- **Check Configuration**: Verify if Bind9 is installed and properly configured.
- **Version Checking**: Ensure that the local script version is up-to-date with the remote version.

---

## Requirements

- **Linux-based OS** (Tested on Debian, Ubuntu, CentOS, and RHEL).
- **Bind9** installed.
- **Curl** for downloading files.

---

## Usage

### Options

- `-r, --run`: Run the script to apply DNS filters.
- `-u, --update [TARGET]`: Update the DNS files.
    - `all`: Update all files (`blockeddomains.db` and `blocked_domain_acl.conf`).
    - `zone`: Update only the `blockeddomains.db` file.
    - `acl`: Update only the `blocked_domain_acl.conf` file.
- `-c, --check`: Check if Bind9 is installed and properly configured.
- `-h, --help`: Show this help message.

### Examples

- Run the script:
    ```bash
    ./bind_filter.sh -r
    ```

- Update all files:
    ```bash
    ./bind_filter.sh -u all
    ```

- Update only the zone file:
    ```bash
    ./bind_filter.sh -u zone
    ```

- Update only the ACL file:
    ```bash
    ./bind_filter.sh -u acl
    ```

- Check Bind9 configuration:
    ```bash
    ./bind_filter.sh -c
    ```

---

## Installation

1. Clone this repository:
    ```bash
    git clone https://github.com/percioandrade/bindfilter.git
    ```

2. Navigate to the script directory:
    ```bash
    cd bindfilter
    ```

3. Make the script executable:
    ```bash
    chmod +x bind_filter.sh
    ```

4. Run the script with the desired options:
    ```bash
    sudo ./bind_filter.sh -r
    ```

5. Or you can run this script with command line
    ```bash
    curl -s https://raw.githubusercontent.com/percioandrade/bindfilter/refs/heads/main/bind_filter.sh | bash -s -- -r
    ```

---

## Troubleshooting

If you encounter any issues:

- Ensure that **Bind9** and **Curl** are installed.
- Check the script's permissions.
- Verify the network connection for downloading files.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

# Script de Filtro para o Bind9

Este script ajuda a filtrar domínios maliciosos conhecidos no Bind9 e manter a configuração atualizada, evitando falsificação e sequestro de DNS.
---

## Funcionalidades

- **Atualizar Arquivos**: Baixar os arquivos mais recentes `blockeddomains.db` e `blocked_domain_acl.conf` do repositório remoto.
- **Executar Filtro DNS**: Aplicar os arquivos baixados na configuração do Bind9.
- **Verificar Configuração**: Verificar se o Bind9 está instalado e configurado corretamente.
- **Verificação de Versão**: Garantir que a versão local do script está atualizada com a versão remota.

---

## Requisitos

- **Sistema Operacional baseado em Linux** (Testado no Debian, Ubuntu, CentOS e RHEL).
- **Bind9** instalado.
- **Curl** para baixar os arquivos.

---

## Uso

### Opções

- `-r, --run`: Executar o script para aplicar os filtros DNS.
- `-u, --update [TARGET]`: Atualizar os arquivos DNS.
    - `all`: Atualizar todos os arquivos (`blockeddomains.db` e `blocked_domain_acl.conf`).
    - `zone`: Atualizar apenas o arquivo `blockeddomains.db`.
    - `acl`: Atualizar apenas o arquivo `blocked_domain_acl.conf`.
- `-c, --check`: Verificar se o Bind9 está instalado e configurado corretamente.
- `-h, --help`: Exibir esta mensagem de ajuda.

### Exemplos

- Executar o script:
    ```bash
    ./bind_filter.sh -r
    ```

- Atualizar todos os arquivos:
    ```bash
    ./bind_filter.sh -u all
    ```

- Atualizar apenas o arquivo de zona:
    ```bash
    ./bind_filter.sh -u zone
    ```

- Atualizar apenas o arquivo de ACL:
    ```bash
    ./bind_filter.sh -u acl
    ```

- Verificar a configuração do Bind9:
    ```bash
    ./bind_filter.sh -c
    ```

---

## Instalação

1. Clone este repositório:
    ```bash
    git clone https://github.com/percioandrade/bindfilter.git
    ```

2. Navegue até o diretório do script:
    ```bash
    cd bindfilter
    ```

3. Torne o script executável:
    ```bash
    chmod +x bind_filter.sh
    ```

4. Execute o script com as opções desejadas:
    ```bash
    sudo ./bind_filter.sh -r
    ```

5. Ou você pode executar este script com linha de comando
    ```bash
    curl -s https://raw.githubusercontent.com/percioandrade/bindfilter/refs/heads/main/bind_filter.sh | bash -s -- -r
    ```
---

## Solução de Problemas

Se você encontrar problemas:

- Certifique-se de que o **Bind9** e o **Curl** estão instalados.
- Verifique as permissões do script.
- Verifique a conexão de rede para o download dos arquivos.

---

## Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para mais detalhes.
