;-------------------------------------------------------------------------------------------
;-- Programa de ejemplo para Bootloader.
;-- Deber� cargarse el programa una vez compilado en modo interativo desde consola:
;--       # sboot -i prog.list
;-------------------------------------------------------------------------------------------
;-- Programa que filtra un conjunto de teclas le�das por del teclado, cada tecla ejecuta
;--   una porci�n de c�digo.
;--
;-- A modo de prueba se utilizan las teclas 'q'(up), 'a'(down), 'o'(left) y 'p'(right).
;-- Para comparar las teclas se utiliza una subrutina parecida a la del ejemplo anterior,
;--   pero simplificada para ahorrar memoria. Las rutinas de retorno son:
;--
;--     * dato1 != dato2 (ret_distintos).
;--     * dato1 == dato2 (ret_iguales).
;--
;--   donde 'dato1' y 'dato2' son los registros que contienen los valores a comparar.
;--
;--   Simplez-F, al no disponer de pila para las llamadas a funci�n. Debe realizar una
;--   adaptaci�n previa de los par�metros y de las direcciones de retorno, modificando
;--   directamente el c�digo de la memoria mediante el uso de un salto incondicional (BR). 
;-------------------------------------------------------------------------------------------
;--
;-- Autor: Juan Manuel Rico (juanmard).
;-- Fecha: Febrero de 2017.
;-- Versi�n: 1.0
;-- 
;--------------------------------------------------------------------------------------------


;-- Acceso a los perifericos
LEDS      EQU 507
TXSTATUS  EQU 508
TXDATA    EQU 509
RXSTATUS  EQU 510
RXDATA    EQU 511


ORG h'40
; Lee primera tecla como caracter ASCII por el puerto serie.
leer_1    LD  /RXSTATUS
          BZ  /leer_1
          LD  /RXDATA
          ST  /tecla_leida

; Se muestra por pantalla a modo prueba.
write_1   LD  /TXSTATUS
          BZ  /write_1
          LD  /tecla_leida
          ST  /TXDATA
                                ; Se intenta la l�gica: <if (tecla_leida == tecla_up) then "goto up" else "goto test_down">. 
test_up   LD  /tecla_leida      ; Se preparan los par�metros.
          ST  /dato1            ; <dato1 = tecla_leida>
          LD  /tecla_up         ; <dato2 = tecla_up>
          ST  /dato2            ;
          LD  /br_code          ; Se preparan direcciones de destino segun la comparaci�n.
          ADD /direc_up         ; @up - El retorno de valores iguales apunta a la funci�n "up" cuya referencia est� en la direcci�n "direc_up".
          ST  /ret_iguales      ;
          LD  /br_code          ; El retorno de valores distintos apunta a "test_down" para seguir probando con la tecla "down".
          ADD /direc_test_down  ; @test_down
          ST  /ret_distintos    ;
          BR  /comparar         ; Una vez preparados los par�metros y las direcciones de retorno se ejecuta la subrutina. 
          
test_down  LD  /tecla_leida      ; Idem para "tecla_down".
           ST  /dato1            ;
           LD  /tecla_down       ;
           ST  /dato2            ;
           LD  /br_code          ;
           ADD /direc_down       ; @down
           ST  /ret_iguales      ;
           LD  /br_code          ;
           ADD /direc_test_right ; @test_right.
           ST  /ret_distintos    ;
           BR  /comparar         ;
           
test_right LD  /tecla_leida      ; Idem para "tecla_right".
           ST  /dato1
           LD  /tecla_right
           ST  /dato2
           LD  /br_code
           ADD /direc_right      ; @right
           ST  /ret_iguales
           LD  /br_code
           ADD /direc_test_left  ; @test_left.
           ST  /ret_distintos
           BR  /comparar

test_left  LD  /tecla_leida      ; Idem para "tecla_left".
           ST  /dato1
           LD  /tecla_left
           ST  /dato2
           LD  /br_code
           ADD /direc_left       ; @left
           ST  /ret_iguales
           LD  /br_code
           ADD /direc_fin        ; @fin
           ST  /ret_distintos
           BR  /comparar

          ; Ejecuta si up.
up        LD  /salida1
          ST  /LEDS
          BR  /fin

          ;Ejecuta si down.
down      LD  /salida2
          ST  /LEDS
          BR  /fin

          ; Ejecuta si right.
right     LD  /salida3
          ST  /LEDS
          BR  /fin

          ; Ejecuta si left.
left      LD  /salida4
          ST  /LEDS
          BR  /fin

; Se vuelve al inicio para leer una nueva tecla.
fin       CLR
          BR  /leer_1

;----------------------------;
;--       Subrutinas       --;
;----------------------------------------------------------------------------------
; Compara dos datos que se cargaron en memoria (dato1 y dato2).
; El algoritmo consiste en ir restando ambos n�meros y ver cual de ellos se hace
; antes cero. Si los dos se hacen cero en la misma iteraci�n es que son iguales.
;----------------------------------------------------------------------------------
; NOTA: En esta versi�n no nos interesa cual es el mayor, o menor sino simplemente
;       si son iguales o distintos. Con esto eliminamos c�digo del anterior ejemplo
;       para ahorrar memoria.
;----------------------------------------------------------------------------------
comparar       LD   /dato1
               DEC
               BZ   /cero_dato1
               ST   /dato1
               LD   /dato2
               DEC
               BZ   /ret_distintos   
               ST   /dato2
               BR   /comparar

; El dato1 lleg� antes a cero que dato2, si son iguales, al restar 
; uno m�s al dato2 se har� tambi�n cero. En otro caso es que son distintos.
cero_dato1     LD   /dato2
               DEC
               BZ   /ret_iguales
ret_distintos  DATA 0               ; dato1 != dato2
ret_iguales    DATA 0               ; dato1 == dato2

;----------------------------;
;-- Variables y constantes --;
;----------------------------;
br_code          BR    /0
tecla_up         DATA  H'71   ; tecla 'q'
tecla_down       DATA  H'61   ; tecla 'a'
tecla_right      DATA  H'70   ; tecla 'p'
tecla_left       DATA  H'6F   ; tecla 'o'
tecla_leida      DATA  H'00
dato1            DATA  H'00
dato2            DATA  H'00
salida1          DATA  H'01
salida2          DATA  H'02
salida3          DATA  H'04
salida4          DATA  H'08

;-------------------------------------;
;-- Tabla de direcciones de memoria --;
;-----------------------------------------------------------------------;
; NOTA: Esta tabla se ha calculado compilando previamente el c�digo y   ;
;       apuntando las direcciones de memoria absolutas. Normalmente de  ; 
;       esto se suele encargar el compilador en dos pasadas, pero para  ;
;       ello habr�a que modificar el ensamblador de Simplez-F (sasm).   ;
;-----------------------------------------------------------------------;
direc_up         DATA  H'74   ; @up
direc_down       DATA  H'77   ; @down
direc_right      DATA  H'7A   ; @right
direc_left       DATA  H'7D   ; @left
;direc_test_up    DATA  H'48   ; @test_up
direc_test_down  DATA  H'53   ; @test_down
direc_test_right DATA  H'5E   ; @test_right
direc_test_left  DATA  H'69   ; @test_left
direc_fin        DATA  H'80   ; @fin

end
