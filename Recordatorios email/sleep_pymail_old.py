##########################################################################################
### Programa para capturar datos de un excel y enviar un correo electronico smtp      ####
### By. Oliver Rojas 23.08.2017, Lab. de Sueño, INTA, Universidad de Chile            ####
##########################################################################################
# La sincronización del gmail es en dos pasos, está registrado el telefono del laboratorio
# +569 xxxx xxxx y el de Oliver +569 xxxx xxxx, la contraseña del gmail es xxxxxxxxxx.
# también quedó registrado la dirección de correo de xxxxxxx@xxxxx.xx -- python 3.7

#%% Cargar librerias y setear espacio de trabajo
import pandas as pd
import os
import smtplib
import datetime as dt
import time
os.chdir("D:/OneDrive/INTA/AplicacionesVarias/Recordatorios email")


# ----------------------------------------------------------------------------------------
# ---- Mensaje para revisar que todo esté ok ---------------------------------------------
# ----------------------------------------------------------------------------------------
# Hora y fecha envío
rutina = pd.read_excel('rutina.xlsx', sheet_name='python')

hoy = dt.date.today()
hoy.day



i = 1
iloc



# Capturar los correos
subj = pd.read_excel("email_actigrafo.xlsx", sheetname="sujetos")
subj = subj.iloc[:, 0:2]


# Informar de lo que se envía
print("\n\n-------------------------------------------------------------------------\n" +
"Agenda envío de correos recordatorios para sujetos con Actigrafos \n" +
"Los correos se enviarán con la siguiente configuración:\n" +
"\nFecha y Hora:\n      " + envio.strftime("%A %d de %B, a las %H:%M") + 
"\n\nA las siguientes personas:")
print(subj)
print("-------------------------------------------------------------------------")


# Verificar la configuración
yesno = ""
while yesno not in ["s", "n"]:
    yesno = input("¿Está correcta esta configuración? [s/n]: ")
else:
    if yesno == "s":
        print("     Ok, el envío de correos se ha agendado correctamente" + 
              "\n     Recuerda no apagar el computador")
    elif yesno == "n":
        print("     Su respuesta fue NO, el programa se detendrá")
        for i in [3,2,1]:
            time.sleep(1)
            print("     " + str(i))
        time.sleep(1)
        exit()



# ----------------------------------------------------------------------------------------
# ---- Antecedentes del correo y función -------------------------------------------------
# ----------------------------------------------------------------------------------------
# Capturar correos, dimensiones y mensaje
# abrir el excel
subj = pd.read_excel("email_actigrafo.xlsx", sheetname="sujetos")
msg = pd.read_excel("email_actigrafo.xlsx", sheetname="mensaje")


# Armar el mensaje en HTML, corrige las tildes
subject = msg.iloc[0,0]
mensaje = (msg.iloc[0,1] + "<br><br>" + msg.iloc[1,1] + "<br><br>" + msg.iloc[2,1] + 
           "<br><br>" + msg.iloc[3,1] + "<br>" + msg.iloc[4,1] + "<br>" + msg.iloc[5,1])

mensaje = mensaje.replace("á", "&aacute;")
mensaje = mensaje.replace("é", "&eacute;")
mensaje = mensaje.replace("í", "&iacute;")
mensaje = mensaje.replace("ó", "&oacute;")
mensaje = mensaje.replace("ú", "&uacute;")
mensaje = mensaje.replace("ñ", "&ntilde;")


# Función Envío del correo, las condiciones son fijas en login
def sendmail(de, para, correo):
    server = smtplib.SMTP(host="smtp.gmail.com", port=587)
    server.starttls()
    server.login("labsueno.inta.uchile@gmail.com", "xioygtbbowsyzsgo")     # Fijo mismo que en "de:"
    server.sendmail(de, para, correo)
    server.close()


# ----------------------------------------------------------------------------------------
# --- Detención del tiempo y envío -------------------------------------------------------
# ----------------------------------------------------------------------------------------
# Datos tiempo envío y sleep
schedule = dt.datetime.combine(sch.iloc[1,1], sch.iloc[1,0])
deltasec  = schedule - dt.datetime.now()
deltasec = deltasec.seconds
time.sleep(deltasec)


# Enviar los correos
print("\nIniciando envío de correos\n")
filas = subj.shape[0]
for i in range(filas):
    de   = "Laboratorio Sueno <labsueno.inta.uchile@gmail.com>"     # Este es fijo
    para = subj.iloc[i,0] + " <" + subj.iloc[i,1] + ">"
    correo = """From: %s\nTo: %s\nSubject: %s\nMIME-Version: 1.0\nContent-type: text/html\n\n%s""" % (de, para, subject, mensaje)
    sendmail(de, para, correo)
    print("Correo enviado a: "+ para)
print("\nTodos los correos fueron enviados... que tengas un buen día")
print("-------------------------------------------------------------------------")