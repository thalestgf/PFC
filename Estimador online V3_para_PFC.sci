//Thales Gonçalves Ferreira
//Engenharia Elétrica - IFSUL
//Bancada Automatizada para a Identificação de Parâmetros - PFC

if(exists("h")==0)then
    h=0;
end
closeserial(h)

clc();
clear();
close(winsid());

deslocamento=30;

leituras = 800;//número de amostrar do experimento

rodada_max=1;

media=10;
testes=15;
index_testes=1;
lambda=1 
teta1=[1/(1D-6);1/(1D-6);1D-6];
teta2=[1D-6;1D-6];
        
com = 7;//computador
h = openserial(com,"2000000,n,8,1");//abri a porta serial

function []= nom_graf(titulo,label_x,label_y,limite)
a=gca();//obtendo as configurações dos eixos
a.parent.background=8; // background = branco
a.grid = [2,2];//o valor [5,5] dá a cor azul do grid
a.title.text=titulo
a.title.font_size = 4;
a.x_label.text=label_x;
a.x_label.font_style = 2; //tipo de fonte - 1=normal; 3=itálico
a.x_label.font_size = 4;
a.y_label.text=label_y;
a.y_label.font_style = 2; //tipo de fonte - 1=normal; 3=itálico
a.y_label.font_size = 4;
a.data_bounds = limite;//limite = [xmin,ymin;xmax,ymax]
e=gce();
e.children(1).thickness=3;
endfunction


function y=vel(t)
   pulsos=36;//número de pulsos gerados pelo encoder
   // no meu caso n = 2*número de dentes
   mult=48;//Valor da redução
   y = (mult*2*%pi*1000000)./(t*pulsos);
endfunction

function y=corrente_cal(ad)
   v=(4.888)*ad//Converte o valor do AD em tensão
   
   // essa equação deve ser obtida calibrando o sensor
   y = (0.0884*v - 1.919)./1000;//calcula a corrente
endfunction


function y=tensao_cal(ad)
   v=(0.004888)*ad//Converte o valor do AD em tensão
   
   y = v;//calcula a tensão
endfunction


function dxdt=f_estimado(_t,x)
    x1=x(1,:);//Corrente
    x2=x(2,:);//Velocidade
    
    if _t<t(leituras/2-1) then
        u=VL
    else
        u=VH       
    end
    
    _b=interpln([medicoes(:,1)';_b_medido_todos'],x2);
    
    _A=[-_R/_L -_K/_L; _K/_j -_b/_j];
    _B=[1/_L; 0];
        
    dxdt=_A*[x1;x2]+_B*u;// Equação de estado
    
endfunction

////////////////////////////Começa a comunicação os o arduino

readserial(h);
sleep(2000)
n = 999;
_n = 0;

while n > 0
    _n = (serialstatus(h)(1))
    sleep(100)
    n= (serialstatus(h)(1)) - _n//2401
end
readserial(h);
////////////////////////////Começa as leituras

rodada=1

pasta= "Resultado com "+string(media)+" medias "+string(clock()(3))+"_"+string(clock()(2))+"_"+string(clock()(1));
mkdir(pasta);

while (index_testes<size(testes)(2)+1)

    mkdir(pasta+"\figuras_"+string(testes(index_testes)));
    mkdir(pasta+"\resultados");

    while (rodada<=rodada_max)
        
        
        hora_inicio=clock();
    
        _R=0;
        _K=0;
        _L=0;
        _j=0;
        _b=0; 
            
        clc();
        disp("Indice testes: "+string(index_testes)+" / "+string(size(testes)(2)));
        disp("Rodada: "+string(rodada)+" / "+string(rodada_max));
    
        p1=eye(3,3)*500
        p2=eye(2,2)*500
        
          
        disp("Medindo a Zona morta")/////////////////////////////////////Medindo V minimo 
        recebe=""
        leitura=""
        writeserial(h,'b');
           
        while (serialstatus(h)(1)) < 1
        
        end
        
        while recebe ~= "!"
            recebe=readserial(h,1);
         
            if(recebe ~= "!")
                leitura=leitura+recebe;      
            end           
        end
    
        V_minimo=strtod(leitura);
        disp("Zona morta "+string(V_minimo))
        disp("Medindo R")///////////////////////////////////////////////////Medindo R
        
        recebe=""
        leitura=""
        writeserial(h,'c');
           
        while (serialstatus(h)(1)) < 1
        
        end
        
        while recebe ~= "!"
            recebe=readserial(h,1);
         
            if(recebe ~= "!")
                leitura=leitura+recebe;      
            end           
        end
        
        leitura=(strsplit(leitura,";"));
        
        clear medicoes;
        
        for i1=1:size(leitura)(1)-1
            medicoes(i1,:)=strtod(strsplit(leitura(i1),","));    
        end  
        
         _R_medido_todos = medicoes(:,1)./medicoes(:,2);
         
         _R_medido = (sum(_R_medido_todos)/(size(_R_medido_todos)(1)))-1;
        
        disp("Resistência "+string(_R_medido))
        disp("Medindo K e B")///////////////////////////////////////////////////Medindo K e B
        
        recebe=""
        leitura=""
        writeserial(h,'d');
           
        while (serialstatus(h)(1)) < 1
        
        end
        
        while recebe ~= "!"
            recebe=readserial(h,1);
         
            if(recebe ~= "!")
                leitura=leitura+recebe;      
            end           
        end
        
        leitura=(strsplit(leitura,";"));
        
        clear medicoes;
        
        for i1=1:size(leitura)(1)-1
            medicoes(i1,:)=strtod(strsplit(leitura(i1),","));    
        end  

        medicoes(:,1)=48.*medicoes(:,1);

        _K_medido_todos = ((medicoes(:,3)./1000)-((_R_medido+1).*((medicoes(:,2)./1000))))./(medicoes(:,1));
    
        _K_medido = sum(_K_medido_todos)/(size(_K_medido_todos)(1));
    
        _b_medido_todos = _K_medido_todos .* ((medicoes(:,2)./1000)./medicoes(:,1));
        
        velocidade_e_b =[medicoes(:,1) _b_medido_todos];
    
        _b_medido=sum(_b_medido_todos)/size(_b_medido_todos)(1);
    
        disp("fator de proporcionalidade "+string(_K_medido))
        
        teta1=[_R_medido/(1D-6);_K_medido/(1D-6);1D-6];
        teta2=[1D-6;1D-6];
        
        writeserial(h,'f');//aciona motor com V low
        
        sleep(1000);        
        
        
        for ind=1:testes(index_testes)
            
             
            writeserial(h,'g');//resetar
            closeserial(h)
            sleep(5000);
    
            h = openserial(com,"2000000,n,8,1");//abri a porta serial
            readserial(h);
            sleep(2000)
            n = 999;
            _n = 0;
            
            while n > 0
                _n = (serialstatus(h)(1))
                sleep(100)
                n= (serialstatus(h)(1)) - _n//2401
            end
            readserial(h);
            sleep(1000);
            readserial(h);
            
            
            corrente=zeros(leituras,1)
            velocidade=zeros(leituras,1)
            tensao=zeros(leituras,1)
            tempo=zeros(leituras,1)  
            for i_med=1:media
                clc();
                disp("Indice testes: "+string(index_testes)+" / "+string(size(testes)(2)));
                disp("Rodada: "+string(rodada)+" / "+string(rodada_max));
                disp("Teste: "+string(ind)+" / "+string(testes(index_testes)));       
                disp("Média: "+string(i_med)+" / "+string(media));      
                disp("R = "+string(_R));         
                disp("L = "+string(_L));         
                disp("K = "+string(_K));         
                disp("j = "+string(_j));         
                disp("b = "+string(_b));          
                recebe=""
                leitura=""

                
                while (serialstatus(h)(1)) > 0 //limpa buffer
                    readserial(h);
                    sleep(100)
                end
               
                
                writeserial(h,'e');//aquisição dos transitórios       
                
                while (serialstatus(h)(1)) < 1000
                
                end
                     
                while serialstatus(h)(1)>0     
                    recebe=recebe+string(readserial(h));
                    sleep(100);
                end
                
                //recebe=readserial(h);
                  
                disp("Dados recebidos")
                
                leitura=strsplit(recebe,";");
                      
                if(size(leitura)(1) >= 800) then
                
                    //aux=zeros(size(leitura)(1)-1,4)
                    
                    for i=1:leituras            
                        if(size(strtod(strsplit(leitura(i,1),",")))(1)==4) then
                            aux(i,:)=strtod(strsplit(leitura(i,1),","));
                        else
                            aux(i,:)=aux(i-1,:);
                        end
                    end                     
                    
                    _tempo=aux(:,1)./1000000;
                    _velocidade=vel(aux(:,2));
                    _tensao=tensao_cal(aux(:,3));
                    _corrente=corrente_cal(aux(:,4));     
                    aux_backup=aux;
                    for i=1:size(tempo)(1)
                        tempo(i)=tempo(i)+_tempo(i)
                    end
                    
                    
                    for i=2:leituras
                        if(_velocidade(i)>700) then
                            _velocidade(i)=_velocidade(i-1);
                        end            
                    end
                    
                    
                    for i=1:size(velocidade)(1)
                        velocidade(i)=velocidade(i)+_velocidade(i)
                    end
                    
                    
                    for i=1:size(tensao)(1)
                        tensao(i)=tensao(i)+_tensao(i)
                    end
                    
                    
                    for i=1:size(corrente)(1)
                        corrente(i)=corrente(i)+_corrente(i)
                    end
                   
               else   
                    i_med=i_med-1;           
               end
                writeserial(h,'f');//aciona motor com V low
           end
            
            tempo=tempo./media
            velocidade=velocidade./media
            tensao=tensao./media
            corrente=corrente./media
            
            tempo_csv(:,ind)=tempo;
            velocidade_csv(:,ind)=velocidade;
            corrente_csv(:,ind)=corrente;
            tensao_csv(:,ind)=tensao;
                
            /////////////////////////////////////////////////////////////Estimando os parâmetros 
           
            
           
            ////////////////////////////////////////////////////filtro
            ordem=0     
            
            x1=corrente;  
            x2=velocidade;  
            
            
            
            for i=1:size(velocidade)(1)-deslocamento
                x2(i)=velocidade(i+deslocamento);            
            end                    
            for i=(size(velocidade)(1)-deslocamento+1):size(velocidade)(1)
                x2(i)=x2(i-1);            
            end                    
            
            
            U=tensao;

            
            clear _x1;
            clear _x2;
            //////////////////////////////////////////////////////FIM DO FILTRO
            

            //x1p=zeros(size(x1)(1),1);
            
            x1p=diff(x1)
            for i=2:size(x1p)(1)
                x1p(i)=x1p(i)/tempo(i+ordem/2)        
             end
            //x2p=zeros(size(x2)(1),1);
            x2p=diff(x2)
            for i=2:size(x2p)(1)
                x2p(i)=x2p(i)/tempo(i+ordem/2)        
             end
             
            
            y1=x1p;
            y2=x2p;
              
            for i=ordem+1:leituras-ordem-1
               
                fi1=[-x1(i); -x2(i); U(i)];
                fi2=[x1(i); -x2(i)];           
                
                k1=(p1*fi1)*(inv(lambda+fi1'*p1*fi1));
                k2=(p2*fi2)*(inv(lambda+fi2'*p2*fi2));
                
                teta1=teta1+k1*(y1(i)-fi1'*teta1);
                teta2=teta2+k2*(y2(i)-fi2'*teta2);
                
                p1=((eye(size(p1)(1),size(p1)(2))-k1*fi1')*p1)/lambda;
                p2=((eye(size(p2)(1),size(p2)(2))-k2*fi2')*p2)/lambda;
        
            end  
              
            _L=1/(teta1(3));
                                   
            _K=_K_medido;
            _R=_R_medido;         
            
            _j=_K/(teta2(1));
            
            _b=_b_medido;       
                        
            if(_L<0)then
                disp("Deu um negativo aqui em L")
               _L=-_L;
            end
            
            if(_j<0)then
                disp("Deu um negativo aqui em j")
               _j=-_j;           
            end
            
            if(_b<0)then                
                disp("Deu um negativo aqui em b")
               _b=-_b;             
            end
            
            teta1=[_R/_L;_K/_L;1/_L];
            teta2=[_K/_j;_b/_j];            
            
            parametros_csv(1,ind)=string(_R);
            parametros_csv(2,ind)=string(_L);
            parametros_csv(3,ind)=string(_K);
            parametros_csv(4,ind)=string(_j);
            parametros_csv(5,ind)=string(_b);
            
        end
          
        
        writeserial(h,'a');//para o motor
        
        
        ////////////////////////////////////////comparando modelo com obtido
                    
            VL=sum(U(1:380))/380;
            VH=sum(U(600:800))/200;
            
            x01=sum(x1(1:380))/380;
            x02=sum(x2(1:380))/380;
        
            _b=sum(_b_medido_todos)/size(_b_medido_todos)(1)
            
            
            _A=[-_R/_L -_K/_L; _K/_j -_b/_j];
            _B=[1/_L; 0];
            
            clc();
            
            disp("Zona morta "+string(V_minimo))
          
            disp("R = "+string(_R))
            disp("L = "+string(_L))
            disp("K = "+string(_K))
            disp("B = "+string(_b))
            disp("J = "+string(_j))
        
            disp("W             b")
            
            disp(velocidade_e_b);
            
            parametros_encontrador(1)="Parametros"
            parametros_encontrador(2)="Tensao minima:,"+string(V_minimo);
            parametros_encontrador(3)="Resistencia:,"+string(_R);
            parametros_encontrador(4)="Indutancia:,"+string(_L);
            parametros_encontrador(5)="Constante K:,"+string(_K);
            parametros_encontrador(6)="Media de b:,"+string(_b);
            parametros_encontrador(7)="Momento de inercia:,"+string(_j);
            parametros_encontrador(8)="V,I,w,b";
            
            for i=1:length(velocidade_e_b(:,1))
                parametros_encontrador(8+i)=string(medicoes(i,3)/1000)+","+string(medicoes(i,2)/1000)+","+string(velocidade_e_b(i,1))+","+string(velocidade_e_b(i,2));
            end
        
        for(i_tempo=1:leituras)
            t(i_tempo)=sum(tempo(1:i_tempo));            
        end
        
        
        if(real(spec(_A)(1))<0 && real(spec(_A)(2))<0) then          
            x = ode("stiff",[x01;x02],0,t,f_estimado);
                _x1=x(1,:)';
                _x2=x(2,:)';
                
                                 
            close(winsid());
            
            figure(90)
            plot(t,x2,"g-");
            //nom_graf("Leitura e modelo estimado velocidade","Tempo ","velocidade");
            plot(t,_x2,"r-");
            legends(["Leitura";"Estimado"],[[3],[5]], with_box=%f, opt=1, font_size=3);
            nom_graf("Velocidade leitura e estimado","Tempo ","velocidade",[0,200;0.8,600]);
            
            figure(91)
            plot(t,corrente,"g-");
            //nom_graf("Leitura e modelo estimado corrente","Tempo ","corrente");
            plot(t,_x1,"r-");
            legends(["Leitura";"Estimado"],[[3],[5]], with_box=%f, opt=1, font_size=3);
            nom_graf("Corrente leitura e estimado","Tempo ","corrente",[0.2,0;0.6,0.3]);

            xs2png(90,pasta+"\figuras_"+string(testes(index_testes))+"\velocidade leitura e estimado "+string(rodada)+".png");
            xs2png(91,pasta+"\figuras_"+string(testes(index_testes))+"\corrente leitura e estimado "+string(rodada)+".png");
                
            resultado(1+(index_testes-1)*10,1+(rodada-1)*3)="Rodada";    
            resultado(2+(index_testes-1)*10,1+(rodada-1)*3)="Erro Corrente";
            resultado(3+(index_testes-1)*10,1+(rodada-1)*3)="Erro velocidade";
            resultado(1+(index_testes-1)*10,3+(rodada-1)*3)="Duracao (min)";
            resultado(2+(index_testes-1)*10,3+(rodada-1)*3)=string((clock()-hora_inicio)(4)*60+(clock()-hora_inicio)(5));
            
            resultado(1+(index_testes-1)*10,2+(rodada-1)*3)=string(rodada);               
            
            resultado(4+(index_testes-1)*10,2+(rodada-1)*3)="Estimados"
            resultado(4+(index_testes-1)*10,3+(rodada-1)*3)="Desejados"
            resultado(4+(index_testes-1)*10,4+(rodada-1)*3)="Erro"
            
            
            resultado(5+(index_testes-1)*10,1)="L"
            resultado(6+(index_testes-1)*10,1)="R"
            resultado(7+(index_testes-1)*10,1)="K"
            resultado(8+(index_testes-1)*10,1)="j"
            resultado(9+(index_testes-1)*10,1)="b"
            
            
            resultado(5+(index_testes-1)*10,2+(rodada-1)*3)=string(_L);
            resultado(6+(index_testes-1)*10,2+(rodada-1)*3)=string(_R);
            resultado(7+(index_testes-1)*10,2+(rodada-1)*3)=string(_K);
            resultado(8+(index_testes-1)*10,2+(rodada-1)*3)=string(_j);
            resultado(9+(index_testes-1)*10,2+(rodada-1)*3)=string(_b);
       
            rodada=rodada+1;
        end
        
    end
    rodada=1;
    index_testes=index_testes+1;

    csvWrite(resultado, pasta+"\resultados\"+"Resultado até teste "+string(testes(index_testes-1))+".csv")

end
closeserial(h);//Fecha a porta serial

csvWrite(resultado, pasta+"\resultados\"+"Resultado"+string(date())+"_"+string(clock()(4))+"_"+string(clock()(5))+"_"+string(rodada)+".csv")

csvWrite(parametros_encontrador, pasta+"\parâmetros.csv")




