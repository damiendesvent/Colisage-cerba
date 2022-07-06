from msilib.schema import Error
import os
import shutil
from sys import prefix
import tkinter as tk
from tkinter import messagebox
from ctypes import windll
from datetime import datetime
import webbrowser
import socket
import subprocess
import mysql.connector
from apscheduler.schedulers.background import BackgroundScheduler
#from pytz import timezone
import glob


# on lit le contenu du fichier variables.txt qui contient les variables
with open('bin/variables.txt') as variables_file :
    variables = variables_file.read()
    variables = variables.splitlines()
    variableDict = {}
    for variable in variables :
        if not (variable.startswith('#') or len(variable) < 2) :
            variable = variable.split(' = ')
            variableDict[variable[0]] = variable[1]

    zip_file = variableDict['zip_file']
    extract_folder = variableDict['extract_folder']
    conf_file_path = variableDict['conf_file_path']
    default_path = variableDict['default_path']
    default_antislash_path = variableDict['default_antislash_path']
    main_file_path = variableDict['main_file_path']
    default_ip = variableDict['default_ip']
    my_file_path = variableDict['my_file_path']
    php_file_path = variableDict['php_file_path']
    pda_track_in_directory = variableDict['pda_track_in_directory']
    pda_track_out_directory = variableDict['pda_track_out_directory']
    minute_synchro_pda_1 = int(variableDict['minute_synchro_pda_1'])
    minute_synchro_pda_2 = int(variableDict['minute_synchro_pda_2'])
    backup_path = variableDict['backup_directory']
    backup_prefix = variableDict['backup_name_prefix']
    type_backup_frequence = variableDict['type_backup_frequence']
    interval_backup_time = int(variableDict['backup_frequence'])


# cette fonction sert de switch au service PDA en activant ou désactivant la tache planifiée + en mettant à jour l'affichage
def start_stop_pda() :
    global pda_status
    pda_status = not pda_status
    if pda_status :
        canvas1.itemconfigure(led_pda_signal, fill='green')
        canvas1.itemconfigure(displayed_pda_signal, text='Programmation : chaque heure à ' + str(minute_synchro_pda_1) + ' et ' + str(minute_synchro_pda_2) + '\n\nService PDA en marche\nDernière synchronisation :\n', fill='green')
        pda_scheduler.start()
    else :
        canvas1.itemconfigure(led_pda_signal, fill='red')
        canvas1.itemconfigure(displayed_pda_signal, text='Programmation : chaque heure à ' + str(minute_synchro_pda_1) + ' et ' + str(minute_synchro_pda_2) + '\n\nService PDA à l\'arrêt', fill='red')
        pda_scheduler.shutdown()


# cette fonction est celle utilisée en tache planifiée pour le service PDA
def import_traca_pda() :
    os.chdir(pda_track_in_directory)
    list_files = glob.glob('*.txt')
    try :
        mydb = mysql.connector.connect(host='localhost', user='root', password='root', database='cerba')
        mycursor = mydb.cursor()
        for file_path in list_files :
            pda_number = file_path[2:8]
            with open(file_path, 'r') as file :
                file_data = file.read()
                traca_list = file_data.splitlines()
                for traca in traca_list :
                    car = traca[0:2]
                    user = traca[2:6]
                    tour =  traca[6:10]
                    step = traca[10:13]
                    site = traca[13:17]
                    action = traca[17:20]
                    box = traca[20:40].strip()
                    time = datetime(year = int(traca[42:46]), month = int(traca[46:48]), day = int(traca[48:50]), hour = int(traca[50:52]), minute = int(traca[52:54]), second = int(traca[54:56])).strftime('%Y-%m-%d %H:%M:%S')
                    image = traca[56:80]
                    signing = traca[80:104]
                    comment = traca[104:152].strip()

                    actual_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

                    box = 'NULL' if len(box) == 0 else '"' + box + '"'
                    comment = 'NULL' if len(comment) == 0 else '"' + comment + '"'

                    query = 'INSERT INTO `tracabilite` (`UTILISATEUR`, `CODE TOURNEE`, `CODE SITE`, `BOITE`, `TUBE`, `ACTION`, `CORRESPONDANT`, `DATE HEURE ENREGISTREMENT`, `DATE HEURE SYNCHRONISATION`, `CODE ORIGINE`, `NUMERO LETTRAGE`, `CODE VOITURE`, `COMMENTAIRE`) VALUES ("' + user + '", ' + tour + ', ' + site + ', ' + box + ', NULL, "' + action + '", NULL, "' + time + '", "' + actual_time + '", "' + pda_number + '", NULL, ' + car + ', ' + comment + ')'
                    mycursor.execute(query)
                    mydb.commit()
                    
            os.remove(file_path)

        mycursor.close()
        mydb.close()
        
        canvas1.itemconfigure(displayed_pda_signal, text='Programmation : chaque heure à ' + str(minute_synchro_pda_1) + ' et ' + str(minute_synchro_pda_2) + '\n\nService PDA en marche\nDernière synchronisation :\n' +  datetime.now().strftime('%d/%m/%Y à %H:%M:%S'), fill='green')

    except Exception as e:
        canvas1.itemconfigure(displayed_pda_signal, text= 'Programmation : chaque heure à ' + str(minute_synchro_pda_1) + ' et ' + str(minute_synchro_pda_2) + '\n\nErreur à :\n' +  datetime.now().strftime('%d/%m/%Y à %H:%M:%S') + '\n' + str(e), fill='orange')


def backup() :
    try :
        subprocess.run('powershell mysqldump --add-drop-table -u root -proot cerba > ' + backup_path + '/' + backup_prefix + datetime.now().strftime('%Y-%m-%d_%H.%M.%S') + '.sql', shell=True) 
        canvas1.itemconfigure(displayed_backup_signal, text='Intervalle : ' + type_backup_frequence + '\nFréquence : ' + str(interval_backup_time) + '\nService de sauvegarde\nen marche\nDernière sauvegarde :\n' +  datetime.now().strftime('%d/%m/%Y à %H:%M:%S'), fill='green')

    except Exception as e:
        canvas1.itemconfigure(displayed_backup_signal, text= 'Intervalle : ' + type_backup_frequence + '\nFréquence : ' + str(interval_backup_time) + '\nErreur à :\n' +  datetime.now().strftime('%d/%m/%Y à %H:%M:%S') + '\n' + str(e), fill='orange')

# cette fonction sert de switch au service backup en activant ou désactivant la tache planifiée + en mettant à jour l'affichage
def start_stop_backup() :
    global backup_status
    backup_status = not backup_status
    if backup_status :
        canvas1.itemconfigure(led_backup_signal, fill='green')
        canvas1.itemconfigure(displayed_backup_signal, text='Intervalle : ' + type_backup_frequence + '\nFréquence : ' + str(interval_backup_time) + '\nService de sauvegarde\nen marche\nDernière sauvegarde :\n', fill='green')
        backup_scheduler.start()
    else :
        canvas1.itemconfigure(led_backup_signal, fill='red')
        canvas1.itemconfigure(displayed_backup_signal, text='Intervalle : ' + type_backup_frequence + '\nFréquence : ' + str(interval_backup_time) + '\nService de sauvegarde\nà l\'arrêt', fill='red')
        backup_scheduler.shutdown()


def install() :
    if not os.path.isdir(extract_folder) :
        if os.path.isfile(zip_file) :
            shutil.unpack_archive(zip_file, extract_folder) # On extrait l'archive du serveur

            # Cette partie modifie le fichier conf du serveur apache pour adapter les chemins d'accès
            with open(conf_file_path, 'r') as conf_file :
                conf_file_data = conf_file.read()
                
            conf_file_data = conf_file_data.replace(default_path, path_w_slash)   # On remplace les chemins d'accès
            conf_file_data = conf_file_data.replace(default_antislash_path, path) # par ceux de l'ordinateur

            with open(conf_file_path, 'w') as conf_file :
                conf_file.write(conf_file_data)
            
            # Cette partie modifie le fichier main du site pour adapter l'IP 
            with open(main_file_path, 'r') as main_file :
                main_file_data = main_file.read()
                
            main_file_data = main_file_data.replace(default_ip, ip)   # On remplace l'IP defaut par l'IP locale de l'ordinateur

            with open(main_file_path, 'w') as main_file :
                main_file.write(main_file_data)

            # Cette partie modifie le fichier conf du serveur mysql pour adapter les chemins d'accès
            with open(my_file_path, 'r') as my_file :
                my_file_data = my_file.read()

            my_file_data = my_file_data.replace(default_path, path_w_slash)

            with open(my_file_path, 'w') as my_file :
                my_file.write(my_file_data)

            # Cette partie modifie le fichier conf du serveur php pour adapter les chemins d'accès
            with open(php_file_path, 'r') as php_file :
                php_file_data = php_file.read()

            php_file_data = php_file_data.replace(default_path, path_w_slash)
            php_file_data = php_file_data.replace(default_antislash_path, path)

            with open(php_file_path, 'w') as php_file :
                php_file.write(php_file_data)

            messagebox.showinfo('Installation réussie','Le serveur est désormais installé')

            installed_label = tk.Label(root, text= 'Installation réussie du serveur le ' + datetime.now().strftime('%d/%m/%Y à %H:%M:%S'), fg='green', font=('helvetica', 10))
            installed_message = canvas1.create_window(250, 300, window=installed_label)
            root.after(16000, canvas1.delete, installed_message)
        
        else :
            messagebox.showerror('Problème de fichier', 'Le fichier MAMP.zip est introuvable,\nVérifiez qu\'il est bien présent.')

    else :
        messagebox.showerror('Serveur déjà installé', 'Le serveur est déjà installé, \ns\'il ne fonctionne pas corectement, appuyez sur Réparer')


def repair() :
    if os.path.isdir(extract_folder) :
        shutil.rmtree(extract_folder)
    install()


def uninstall() :
    safety_msg = messagebox.askyesno('Désinstaller le serveur', 'Etes-vous sûr de vouloir le désinstaller ?')
    if safety_msg :
        if os.path.isdir(extract_folder) :
            shutil.rmtree(extract_folder)
        uninstalled_label = tk.Label(root, text= 'Désinstallation réussie du serveur le ' + datetime.now().strftime('%d/%m/%Y à %H:%M:%S'), fg='brown', font=('helvetica', 10))
        uninstalled_message = canvas1.create_window(250,300,window=uninstalled_label)
        root.after(8000, canvas1.delete, uninstalled_message)


def quit() :
    stop_all()
    root.destroy()


def disable_event() :
    pass

def start_stop_web_server() :
    global web_server_status
    web_server_status = not web_server_status
    if (web_server_status) :
        launch_server()
    else :
        stop_server()

def launch_server() :
    if os.path.isfile(extract_folder + '/MAMP.exe') :
        try : 
            subprocess.call('powershell Start-Process -FilePath ' + extract_folder + '/MAMP.exe -WindowStyle Minimized', creationflags=subprocess.CREATE_NO_WINDOW) 
            canvas1.itemconfigure(led_web_signal, fill='green')
            success_text = 'Serveur démarré le ' + datetime.now().strftime('%d/%m/%Y à %H:%M:%S') + '\nà l\'adresse ' + ip
            canvas1.itemconfigure(displayed_web_signal, text=success_text, fill='green')

        except ValueError: 
            messagebox.showerror('Impossible de lancer le serveur', 'Impossible de lancer le serveur.\nVeuillez réessayer ou appuyer sur Réparer')

    else :
        messagebox.showerror('Impossible de lancer le serveur', 'Impossible de lancer le serveur.\nVeuillez réessayer ou appuyer sur Réparer')


def stop_server() :
    subprocess.call('powershell if (get-process mamp -ErrorAction SilentlyContinue){(get-process mamp).closeMainWindow()}', creationflags=subprocess.CREATE_NO_WINDOW)
    canvas1.itemconfigure(led_web_signal, fill='red')
    canvas1.itemconfigure(displayed_web_signal, text='Serveur web à l\'arrêt', fill='red')


def open_website() :
    if not subprocess.call('powershell get-process mamp -errorAction SilentlyContinue', creationflags=subprocess.CREATE_NO_WINDOW) :
        webbrowser.open('http://' + ip)
    
    else :
        messagebox.showerror('Serveur non démarré', 'Le serveur n\'est pas démarré,\nappuyez d\'abord sur Démarrer le serveur')


def launch_all() :
    global pda_status
    if not pda_status : start_stop_pda()
    global web_server_status
    if not web_server_status : start_stop_web_server()
    global backup_status
    if not backup_status : start_stop_backup()


def stop_all() :
    global pda_status
    if pda_status : start_stop_pda()
    global web_server_status
    if web_server_status : start_stop_web_server()
    global backup_status
    if backup_status : start_stop_backup()


def stop_process() :
    subprocess.run('taskkill /IM httpd.exe /IM mysqld.exe /F')

path = os.getcwd()
path_w_slash = path.replace('\\','/')
global ip
ip = socket.gethostbyname(socket.gethostname())

global pda_status
pda_status = False

global web_server_status
web_server_status = False

global backup_status
backup_status = False

pda_scheduler = BackgroundScheduler()
pda_scheduler.add_job(import_traca_pda, 'cron', minute=minute_synchro_pda_1, timezone='Europe/Berlin')
pda_scheduler.add_job(import_traca_pda, 'cron', minute=minute_synchro_pda_2, timezone='Europe/Berlin')

backup_scheduler = BackgroundScheduler()
if (type_backup_frequence == 'seconde') :
    backup_scheduler.add_job(backup, 'interval', seconds=interval_backup_time, timezone='Europe/Berlin')
elif (type_backup_frequence == 'minute') :
    backup_scheduler.add_job(backup, 'interval', minutes=interval_backup_time, timezone='Europe/Berlin')
elif (type_backup_frequence == 'heure') :
    backup_scheduler.add_job(backup, 'interval', hours=interval_backup_time, timezone='Europe/Berlin')
elif (type_backup_frequence == 'jour') :
    backup_scheduler.add_job(backup, 'interval', days=interval_backup_time, timezone='Europe/Berlin')    

root= tk.Tk(className='Serveur de colisage')
root.protocol('WM_DELETE_WINDOW', disable_event) # désactive la croix de fermeture Windows
root.iconbitmap('bin/Cerba.ico')
canvas1 = tk.Canvas(root, width = 800, height = 500)
canvas1.pack()

windll.shcore.SetProcessDpiAwareness(1)

launch_all_button = tk.Button(text='Démarrer tous\nles services', command=launch_all, bg='green', fg='white')
canvas1.create_window(100,100, window=launch_all_button)

open_website_button = tk.Button(text='Accéder\nau\nsite web', command=open_website, bg='blue', fg='white')
canvas1.create_window(400, 100, window=open_website_button)

stop_all_button = tk.Button(text='Arrêter tous\nles services', command=stop_all, bg='brown', fg='white')
canvas1.create_window(700,100, window=stop_all_button)

quit_button = tk.Button(text='Quitter', command=quit, bg='grey', fg='white')
canvas1.create_window(770,20, window=quit_button)

canvas1.create_line(50,150,750,150) # première ligne horizontale

led_pda_signal = canvas1.create_oval(20,190,40,210, fill='red')
displayed_pda_signal = canvas1.create_text(20,270, anchor= 'w', text='Programmation : chaque heure à ' + str(minute_synchro_pda_1) + ' et ' + str(minute_synchro_pda_2) + '\n\nService PDA à l\'arrêt', fill='red')

pda_button = tk.Button(text='Activer/Désactiver la\nréception des fichiers PDA', command=start_stop_pda, bg='grey', fg='white')
pda_window = canvas1.create_window(130, 380, window=pda_button)

canvas1.create_line(266,180,266,400) # première ligne verticale

led_web_signal = canvas1.create_oval(280,190,300,210, fill='red')
displayed_web_signal = canvas1.create_text(280,270, anchor= 'w', text='Serveur web à l\'arrêt', fill='red')

web_server_button = tk.Button(text='Démarrer/Arrêter \nle serveur web', command=start_stop_web_server, bg='grey', fg='white')
canvas1.create_window(350, 380, window=web_server_button)

stop_process_button = tk.Button(text='Stopper les\nprocessus', command=stop_process, bg='brown', fg='white')
canvas1.create_window(450,380,window=stop_process_button)

canvas1.create_line(533,180,533,400) # deuxième ligne verticale

led_backup_signal = canvas1.create_oval(580,190,600,210, fill='red')
displayed_backup_signal = canvas1.create_text(580,270, anchor= 'w', text='Intervalle : ' + type_backup_frequence + '\nFréquence : ' + str(interval_backup_time) + '\nService sauvegarde à l\'arrêt', fill='red')

backup_button = tk.Button(text='Activer/Désactiver la\nsauvegarde automatique', command=start_stop_backup, bg='grey', fg='white')
canvas1.create_window(650,380, window=backup_button)

canvas1.create_line(50,420,750,420) # deuxième ligne horizontale

install_button = tk.Button(text='Installer le serveur',command=install, bg='green',fg='white')
canvas1.create_window(100, 460, window=install_button)

repair_button = tk.Button(text='Réparer le serveur', command=repair, bg='brown', fg='white')
canvas1.create_window(400, 460, window=repair_button)

uninstall_button = tk.Button(text='Désinstaller le serveur', command=uninstall, bg='red', fg='white')
canvas1.create_window(700, 460, window=uninstall_button)







root.mainloop()