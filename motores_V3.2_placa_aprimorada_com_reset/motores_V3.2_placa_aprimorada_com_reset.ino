/* Legenda dos comandos
   a - Desliga o motor (em mili)
   b - Medir tensão mínima (em mili)
   c - Medir resistência (em ohm)
   d - Medir constante de torque e atrito
   e - Medir transitórios
   f - Aciona motor com v_low
   g - resetar
   z - Monitor em tempo real

*/

#define ts 1000 //1000us

#define v_low   2
#define v_high   3

#define v_max 4500

#define da8   5
#define da7   6
#define da6   7
#define da5   8
#define da4   9
#define da3   10
#define da2   11
#define da1   12

#define sensor_i  0
#define sensor_v  1
#define encoder   2

#define med   10

#define leituras 800

float v_min_motor = 1000;//mV
float r_motor = 0;
float k_motor = 0;

int contador_tempo = 0;
float tempo_acumulado = 0;

long int tempo = 99999999, tempo_anterior = 0;
char selecao = 'a';
int flag = 0;
bool flag_girando = 0;

double tempo_leitura = 0, tempo_leitura_ant = 0;
char c;
int contador = 0;
int cont = 0;
int x = 0;
bool flag_change = 1;

#define config_int_default attachInterrupt(digitalPinToInterrupt(encoder), int_encoder, CHANGE);

void (*funcReset)() = 0;

void setup() {
  Serial.begin(2000000);

  //Definir pinos como entradas e saídas
  pinMode(da8, OUTPUT);
  pinMode(da7, OUTPUT);
  pinMode(da6, OUTPUT);
  pinMode(da5, OUTPUT);
  pinMode(da4, OUTPUT);
  pinMode(da3, OUTPUT);
  pinMode(da2, OUTPUT);
  pinMode(da1, OUTPUT);

  pinMode(13, OUTPUT);

  pinMode(sensor_i, INPUT);
  pinMode(sensor_v, INPUT);

  //configura interrupção externa
  pinMode(encoder, INPUT_PULLUP);
  config_int_default
  selecao_tensao(0);
  flag = 0;


}



void loop() {
  //Serial.println(calculo_resistencia());
  /*do {
    float w = 0;
    selecao_tensao(4);

    Serial.println(leitura_corrente(1000));
    delay(1000);
    } while (1 == 1);*/

  switch (selecao) {
    case 'a':
      selecao_tensao(0);
      break;
    case 'b':

      //Serial.print("Tensão mínima: ");
      v_min_motor = tensao_minima();
      Serial.print(v_min_motor);
      delay(200);
      Serial.print('!');
      //Serial.println(" mV");
      selecao = 1;
      break;
    case 'c':
      calculo_resistencia();
      //Serial.print("R: ");

      //Serial.println(" ohm");
      selecao = 1;
      break;
    case 'd':
      calculo_k();

      selecao = 1;
      break;
    case 'e':

      selecao_tensao(v_low);
      delay(100);
      tempo_leitura = 0;

      for (contador = 0; contador < leituras; contador++) {


        if (contador == leituras / 2) {
          selecao_tensao(v_high);
        }

        if (contador > 0) {
          tempo_leitura = micros() - tempo_leitura_ant;
          delayMicroseconds(ts - tempo_leitura);
        }
        //tempo_leitura = micros() - tempo_leitura_ant;
        tempo_leitura_ant = micros();

        Serial.print(String(ts) + ',' + String(tempo) + ',' + String(analogRead(sensor_v)) + ',' + String(analogRead(sensor_i)) + ';');

      }
      selecao = 6;
      selecao_tensao(v_low);
      delay(100);
      Serial.print('!');
      break;
    case 'f':
      selecao_tensao(v_low);

      //Serial.println(digitalRead(encoder));
      //delay(10);
      break;
    case 'g':

      funcReset();
      break;
    case 'z':
      float v_pot = (analogRead(2) * 5.0) / 1023.0;
      selecao_tensao(v_pot);

      //selecao_tensao(4);
      Serial.println("V: " + String(leitura_tensao(2000)) + " I: " + String(leitura_corrente(2000)) + "   w: " + String(leitura_velocidade(2000)));
      break;
  }
}





#define media_v 10
float tensao_minima() {
  float v_motor_media = 0;
  for (int x = 0; x < media_v; x++) {
    bool flag_led = 0;
    float v_out = 0, v_motor = 0;
    float corrente = 0, corrente_anterior = 0;
    flag_girando = 0;
    selecao_tensao(0);
    delay(50);
    do {
      v_motor = leitura_tensao(100);
      corrente_anterior = corrente;
      flag_led = !flag_led;
      digitalWrite(13, flag_led);
      v_out = v_out + 0.05;
      selecao_tensao(v_out);
      delay(50);
      corrente = leitura_corrente(500);

    } while (corrente > corrente_anterior);
    //Serial.println(v_motor);
    v_motor_media = v_motor_media + v_motor;
    selecao_tensao(0);

  }
  v_motor_media = v_motor_media / media_v;
  return v_motor_media;
}

#define media_r 5
float calculo_resistencia() {
  float resistencia_media = 0;
  for (int x = 0; x < media_r; x++) {
    bool flag_led = 0;
    float v_out = 0.2;
    selecao_tensao(v_out);
    do {
      Serial.print(String(leitura_tensao(2000)) + ',' + String(leitura_corrente(2000)) + ';');
      flag_led = !flag_led;
      digitalWrite(13, flag_led);
      v_out = v_out + 0.05;
      selecao_tensao(v_out);
      delay(10);
    } while (leitura_tensao(100) <= ((v_min_motor) * 0.8));
    selecao_tensao(0);
  }
  delay(200);
  Serial.print('!');
}

void calculo_k() {

  float k_media = 0;

  bool flag_led = 0;
  float v_out = 1.5 * (v_min_motor / 1000.0);

  int contador = 0;
  selecao_tensao(v_out);

  float i = 0;
  float w = 0;
  float vm = 0;

  do {
    v_out = v_out + 0.1;
    flag_led = !flag_led;
    digitalWrite(13, flag_led);
    selecao_tensao(v_out);
    delay(2000);


    w = leitura_velocidade(100);
    i = leitura_corrente(2000);
    vm = leitura_tensao(2000);

    Serial.print(String(w) + ',' + String(i) + ',' + String(vm) + ';');

  } while (vm <= v_max);
  selecao_tensao(0);
  delay(200);
  Serial.print('!');
}

float leitura_tensao(float media) {
  int x1;
  float leitura = 0;
  for (x1 = 0; x1 < media; x1++) {
    leitura = leitura + analogRead(sensor_v);
  }
  leitura = leitura / media;
  leitura = (leitura * 5.0) / 1.0230;
  return leitura;
}

float leitura_corrente(float media) {
  int x1;
  float leitura = 0;
  for (x1 = 0; x1 < media; x1++) {
    leitura = leitura + analogRead(sensor_i);
  }
  leitura = leitura / media;
  leitura = (leitura * 5.0) / 1.0230;
  leitura = 0.0884 * leitura;
  return leitura;
}



float leitura_velocidade(int media) {
  float w = 0;
  double tempo_calculo_velocidade = 0;
  //attachInterrupt(digitalPinToInterrupt(encoder), int_encoder, FALLING);
  detachInterrupt(digitalPinToInterrupt(encoder));
  //config_int_default
  flag_change = 0;
  contador_tempo = 0;
  tempo_acumulado = 0;


  tempo = 0;
  tempo_anterior = micros();
  
  while (digitalRead(encoder) == 0);
  
  for (contador_tempo = 0; contador_tempo < media; contador_tempo++) {
    while (digitalRead(encoder) == 1);
    tempo = tempo + (micros() - tempo_anterior) ;
    tempo_anterior = micros();
    while (digitalRead(encoder) == 0);
  }

  tempo_calculo_velocidade = tempo / media;

  //w = (301592894.745) / (tempo_calculo_velocidade * 18.0);//motor
  w = w + (349065.85) / (tempo_calculo_velocidade);//roda
  //w = (301592894.745) / (tempo_calculo_velocidade * 36.0);//motor change
  //w = (6283185.307) / (tempo_calculo_velocidade * 36.0);//roda change

  config_int_default
  flag_change = 1;

  return w;
}


void int_encoder()
{
  //Serial.print(digitalRead(encoder));
  flag_girando = 1;

  double _tempo = tempo;

  tempo = micros() - tempo_anterior ;
  tempo_anterior = micros();

  contador_tempo++;
  tempo_acumulado = tempo_acumulado + tempo;

  //Serial.println(tempo);

}

void serialEvent() {
  while (Serial.available()) {
    selecao = Serial.read();
  }
}

void selecao_tensao(float V) {

  if (V > 5) {
    V = 5;
  }
  if (V < 0) {
    V = 0;
  }

  V = V * 255.0 / 5.0;

  digitalWrite(da1, ((int)V & 0b00000001));
  digitalWrite(da2, ((int)V & 0b00000010) >> 1);
  digitalWrite(da3, ((int)V & 0b00000100) >> 2);
  digitalWrite(da4, ((int)V & 0b00001000) >> 3);
  digitalWrite(da5, ((int)V & 0b00010000) >> 4);
  digitalWrite(da6, ((int)V & 0b00100000) >> 5);
  digitalWrite(da7, ((int)V & 0b01000000) >> 6);
  digitalWrite(da8, ((int)V & 0b10000000) >> 7);
}
