# CustomerSuccessBalancing

Código com a resolução do desafio proposto [aqui](https://tech.rdstation.com/).

A implementação encontra-se no diretório `lib/` e os testes em `test/`.

Além dos testes originais foram adicionados alguns outros para validar regras
de negócio listadas [como premissas nos requerimentos](https://tech.rdstation.com/#premissas)
(principalmente no que se refere à validação do input).

## Clonando o repositório

```bash
git clone git@github.com:meleu/customer-success-balancing
cd customer-success-balancing
```

### Versão do Ruby

O código foi escrito e testado com Ruby 3.2.2.

Também foi validado no Ruby 3.1+

O repositório contem o arquivo `.tool-versions`. Portanto, caso tenha `asdf` instalado,
é possível instalar a versão correta do Ruby com:

```bash
asdf install
```

### Executando os testes

Assumindo que o repositório já foi clonado e a versão do Ruby devidamente instalada,
basta executar:

```bash
ruby test/customer_success_balancing_test.rb
```
