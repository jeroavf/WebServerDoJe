/*
 * Web Server com ativação de LED e exibição da temperatura ambiente
 * Autor: Jeronimo Avelar Filho - jeronimo@blogdoje.com.br
 *        www.blogdoje.com.br
 * Baseado no exemplo WebServer da versão 0018 da IDE Arduino e no exemplo
 * do blog http://www.scienceprog.com/getting-hands-on-arduino-ethernet-shield/
 * Alterado em 11/05/2011 por Jeronimo:
 *      Atualização para o ambiente Arduino 0022
 *      - Utilização do objeto String no lugar da library WString.h
 *      - Inclusão de bibliotecas necessárias para o funcionamento da library Ethernet.h 
 */

#include <Client.h>
#include <Ethernet.h>
#include <Server.h>
#include <Udp.h>
#include <SPI.h>


byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 169, 1, 201 };
Server server(80);
int conta_caracter=0 ;
int max_linha = 80 ; 
String linha_de_entrada = String(max_linha) ;
int ledPin = 4 ;
boolean LEDON = false ;

float temperatura ;
float r1 = 10000.0 ;  // valor da resistencia
                      // fixa do divisor de tensão

void setup()
{
  pinMode(ledPin, OUTPUT) ;
  Serial.begin(9600) ;
  Ethernet.begin(mac, ip);
  server.begin();
  digitalWrite(ledPin,LOW) ;
  
}

void loop()
{
  Client client = server.available();
  if (client) {
    // an http request ends with a blank line
    boolean current_line_is_blank = true;
    conta_caracter=0 ;
    linha_de_entrada="" ;
    
    while (client.connected()) {
      if (client.available()) {
        // recebe um caracter enviado pelo browser
        char c = client.read();
        // se a linha não chegou ao máximo do armazenamento 
        // então adiciona a linha de entrada
        if(linha_de_entrada.length() < max_linha) {
          linha_de_entrada.concat(c) ; 
        }  
 
        // Se foi recebido um caracter linefeed - LF
        // e a linha está em branco , a requisição http encerrou.
        // Assim é possivel iniciar o envio da resposta
        
        if (c == '\n' && current_line_is_blank) {
          // envia uma resposta padrão ao header http recebido
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println();
          // começa a enviar o formulário
          client.print("<html>") ;
          client.print("<body>");
          
          // le sensor de temperatura , ele fornece uma resistencia
          // que é função da temperatura 
          int analogValue = analogRead(0);
          temperatura = converteTemp( analogValue) ;
          client.println("<h2>TEMPERATURA AMBIENTE</h2><hr/>");
          client.println(temperatura) ; 
          client.println("<br>") ;
          client.println("<h2>CONTROLE DO LED</h2><hr/>");
          client.println("<form method=get name=LED>") ;
          
          client.println("LIGA <input ")  ;
          // verifica o status do led e ativa o radio button 
          // correspondente
          if(LEDON) {
            client.println("checked='checked'") ;
          }
          client.println("name='LED' value='ON' type='radio' >");
          
          client.println("DESLIGA <input ")  ;
          if(!LEDON) {
            client.println("checked='checked'") ;
          }
          client.println("name='LED' value='OFF' type='radio' >");
          // exibe o botão do formulário
          client.println("<br><br><br><input type=submit value='ATUALIZA'></form>") ;
          client.println("<br><font color='blue' size='3'>Acesse <a href=http://www.blogdoje.com.br/>www.blogdoje.com.br</a>");
          client.println("</body>") ;
          client.println("</html>");

          break;
        }
        
        if (c == '\n') {
          // se o caracter recebido é um linefeed então estamos começando a receber uma 
          // nova linha de caracteres
          // os codigos de impressão abaixo são para depuração e visualizar no monitor serial 
          // o que está chegando do browser
          Serial.print(linha_de_entrada.length()) ;
          Serial.print("->") ;
          Serial.print(linha_de_entrada) ;
          // Analise aqui o conteudo enviado pelo submit
          if(linha_de_entrada.indexOf("GET") != -1 ){
            // se a linha recebida contem GET e LED=ON enão guarde o status do led
            if(linha_de_entrada.indexOf("LED=ON") != -1 ){ 
              digitalWrite(ledPin,HIGH) ;
              LEDON=true ;
            }
            if(linha_de_entrada.indexOf("LED=OFF") != -1 ){ 
            // se a linha recebida contem GET e LED=OFF enão guarde o status do led
              digitalWrite(ledPin,LOW) ;
              LEDON=false ;
            }
          }

          current_line_is_blank = true;
          linha_de_entrada="" ;
          
        } else if (c != '\r') {
          // recebemos um carater que não é linefeed ou retorno de carro 
          // então recebemos um caracter e a linha de entrada não está mais vazia
          current_line_is_blank = false;
        }
      }
    }
    // dá um tempo para  o browser receber os caracteres
    delay(1);
    client.stop();
  }
}

float converteTemp( int av) {
   // determina a resistencia do sensor 
   float r = (av * r1 ) / ( 1023 - av) ;

   r = r / 1000.0 ;   
 
   // calcula a temperatura com base equação cubica 
   // deduzida a partir dos dados da curva do fornecedor
   float t = 73.5923087897328 - (7.55658933843571 * r) + (0.310715305324934 * r * r )  - ( 0.00459929744270984 * r * r *  r) ;
   return t ;
 }


