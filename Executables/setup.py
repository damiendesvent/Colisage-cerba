from codecs import ignore_errors
from concurrent.futures import thread
from genericpath import isfile
import os
import shutil
import tkinter as tk
from tkinter import ttk
from tkinter import messagebox
from tkinter import filedialog as fd
from ctypes import windll
from datetime import datetime
import webbrowser
import socket
import subprocess
import mysql.connector
from apscheduler.schedulers.background import BackgroundScheduler
import glob
import locale
import threading
import time
import random
locale.setlocale(locale.LC_TIME,'')

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
    extract_folder = variableDict['chemin_installation_serveur']
    apache_file_path = variableDict['apache_file_path']
    default_path = variableDict['default_path']
    default_antislash_path = variableDict['default_antislash_path']
    main_file_path = variableDict['main_file_path']
    default_ip = variableDict['default_ip']
    my_file_path = variableDict['my_file_path']
    php_file_path = variableDict['php_file_path']
    pda_track_in_directory = variableDict['chemin_reception_fichier_PDA']
    images_in_directory = variableDict['chemin_reception_images_PDA']
    minute_synchro_pda_1 = int(variableDict['minute_synchro_pda_1'])
    minute_synchro_pda_2 = int(variableDict['minute_synchro_pda_2'])
    backup_path = variableDict['chemin_sauvegardes']
    backup_prefix = variableDict['prefixe_fichier_sauvegarde']
    records_traca_path = variableDict['chemin_archives_tracabilites']
    records_prefix = variableDict['prefixe_fichier_archive']
    type_backup_frequence = variableDict['type_sauvegarde']
    interval_backup_time = int(variableDict['frequence_sauvegarde'])
    last_reception_in_directory = variableDict['chemin_reception_fichiers_boite']
    last_reception_out_directory = variableDict['chemin_envoi_fichiers_boite']
    type_reception_frequence = variableDict['type_synchronisation']
    reception_frequence = int(variableDict['frequence_synchronisation'])
    max_backup_files = int(variableDict['nombre_maximum_fichiers_sauvegarde'])
    cleaning_hour = int(variableDict['heure_nettoyage_boite'])


# cette fonction sert de switch au service PDA en activant ou désactivant la tache planifiée + en mettant à jour l'affichage
def start_stop_pda() :
    global pda_status
    if (web_server_status or pda_status) :
        pda_status = not pda_status
        if pda_status :
            canvas1.itemconfigure(led_pda_signal, fill='green')
            canvas1.itemconfigure(displayed_pda_signal, text='Programmation : chaque heure à ' + str(minute_synchro_pda_1) + ' et ' + str(minute_synchro_pda_2) + '\nService PDA en marche\nDernière synchronisation :\n', fill='green')
            pda_scheduler.resume()
        else :
            canvas1.itemconfigure(led_pda_signal, fill='red')
            canvas1.itemconfigure(displayed_pda_signal, text='Programmation : chaque heure à ' + str(minute_synchro_pda_1) + ' et ' + str(minute_synchro_pda_2) + '\nService PDA à l\'arrêt', fill='red')
            pda_scheduler.pause()
    else :
        messagebox.showerror(title='Serveur web éteint', message='Veuillez allumer le serveur web\npour activer la réception des fichiers PDA')


# cette fonction est celle utilisée en tache planifiée pour le service PDA
def import_traca_pda() :
    os.makedirs(pda_track_in_directory, exist_ok=True)
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
                    image = traca[56:80].strip()
                    signing = traca[80:104].strip()
                    comment = traca[104:152].strip()

                    actual_time = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

                    box = 'NULL' if len(box) == 0 else '"' + box + '"'
                    image = 'NULL' if len(image) == 0 else '"' + image + '"'
                    signing = 'NULL' if len(signing) == 0 else '"' + signing + '"'
                    comment = 'NULL' if len(comment) == 0 else '"' + comment + '"'

                    query = 'INSERT INTO `tracabilite` (`UTILISATEUR`, `CODE TOURNEE`, `CODE SITE`, `BOITE`, `TUBE`, `ACTION`, `CORRESPONDANT`, `DATE HEURE ENREGISTREMENT`, `DATE HEURE SYNCHRONISATION`, `CODE ORIGINE`, `NUMERO LETTRAGE`, `CODE VOITURE`, `PHOTO`, `SIGNATURE`,`COMMENTAIRE`) VALUES ("' + user + '", (select `code tournee` from `entetes feuille de route` where `ordre affichage pda` = ' + tour + ' LIMIT 1), ' + site + ', ' + box + ', NULL, "' + action + '", NULL, "' + time + '", "' + actual_time + '", "' + pda_number + '", NULL, ' + car + ', ' + image + ', ' + signing + ', ' + comment + ')'
                    mycursor.execute(query)
                    mydb.commit()
                    
            os.remove(file_path)

        mycursor.close()
        mydb.close()

        os.makedirs(images_in_directory, exist_ok=True)
        imagesList = os.listdir(images_in_directory)
        for image_name in imagesList :
            image_src_path = images_in_directory + '/' + image_name
            image_dst_path = extract_folder + '/htdocs/flutter_api/Images/' + image_name
            print('src : '+image_src_path)
            print('dst : ' + image_dst_path)
            if os.path.isfile(image_dst_path) :
                os.unlink(image_dst_path)
            shutil.move(image_src_path, image_dst_path)
        
        canvas1.itemconfigure(displayed_pda_signal, text='Programmation : chaque heure à ' + str(minute_synchro_pda_1) + ' et ' + str(minute_synchro_pda_2) + '\nService PDA en marche\nDernière synchronisation :\n' +  datetime.now().strftime('%d/%m/%Y à %H:%M:%S'), fill='green')

    except Exception as e:
        canvas1.itemconfigure(displayed_pda_signal, text= 'Programmation : chaque heure à ' + str(minute_synchro_pda_1) + ' et ' + str(minute_synchro_pda_2) + '\nErreur à :\n' +  datetime.now().strftime('%d/%m/%Y à %H:%M:%S') + '\n' + str(e), fill='orange')


def backup(changeDisplay = True) :
    os.makedirs(records_traca_path, exist_ok=True)
    try :
        backup_files = sorted(glob.glob('*.sql', root_dir=backup_path))
        while len(backup_files) > max_backup_files :
            os.unlink(backup_path + '/' + backup_files[0])
            backup_files = sorted(glob.glob('*.sql', root_dir=backup_path))
        subprocess.run(extract_folder + '/bin/mysql/bin/mysqldump -u root -proot cerba > ' + backup_path + '/' + backup_prefix + datetime.now().strftime('%Y-%m-%d_%H-%M-%S') + '.sql', shell=True) 
        if changeDisplay : canvas1.itemconfigure(displayed_backup_signal, text='Intervalle : ' + type_backup_frequence + '\nFréquence : ' + str(interval_backup_time) + '\nService de sauvegarde\nen marche\nDernière sauvegarde :\n' +  datetime.now().strftime('%d/%m/%Y à %H:%M:%S'), fill='green')
        
        mydb = mysql.connector.connect(host='localhost', user='root', password='root', database='cerba')
        mycursor = mydb.cursor(buffered=True)
        query = 'SELECT `DATE HEURE SYNCHRONISATION` FROM `tracabilite` ORDER BY `DATE HEURE SYNCHRONISATION` ASC LIMIT 1'
        mycursor.execute(query)
        synchronizing_time = mycursor.fetchone()
        actual_time = datetime.now()

        # la partie qui suit est dédiée à la création des archives de traçabilité
        if synchronizing_time != None and synchronizing_time[0].month % 12 != actual_time.month and (synchronizing_time[0].month + 1) % 12 != actual_time.month and changeDisplay :
            mycursor.execute('TRUNCATE `backup_tracabilite`')
            mydb.commit()
            mycursor.execute('INSERT INTO `backup_tracabilite` SELECT * FROM `tracabilite` WHERE `date heure synchronisation` BETWEEN "' + synchronizing_time[0].strftime('%Y-%m') + '-01-00:00:00" AND "' + synchronizing_time[0].strftime('%Y-%m') + '-31-23:59:59"')
            mydb.commit()
            mycursor.execute('SELECT PHOTO,SIGNATURE FROM `backup_tracabilite`')
            items = mycursor.fetchall()
            files = os.listdir(extract_folder + '/htdocs/flutter_api/Images')
            os.makedirs(records_traca_path + '/' + synchronizing_time[0].strftime('%Y-%m_%B'), exist_ok=True)
            for picture,signing in items :
                if picture != None :
                    for file in files :
                        if picture in file and not os.isfile(records_traca_path + '/' + synchronizing_time[0].strftime('%Y-%m_%B') + '/' + file) :
                            shutil.move(extract_folder + '/htdocs/flutter_api/Images/' + file, records_traca_path + '/' + synchronizing_time[0].strftime('%Y-%m_%B') + '/' + file)
                            break
                if signing != None :
                    for file in files :
                        if signing in file and not os.isfile(records_traca_path + '/' + synchronizing_time[0].strftime('%Y-%m_%B') + '/' + file) :
                            shutil.move(extract_folder + '/htdocs/flutter_api/Images/' + file, records_traca_path + '/' + synchronizing_time[0].strftime('%Y-%m_%B') + '/' + file)
                            break
            if os.isfile(records_traca_path + '/' + records_prefix + synchronizing_time[0].strftime('%Y-%m_%B') + '.sql') :
                subprocess.run(extract_folder + '/bin/mysql/bin/mysqldump -u root -proot cerba backup_tracabilite > ' + records_traca_path + '/' + records_prefix + synchronizing_time[0].strftime('%Y-%m_%B') + actual_time.strftime('%Y-%m-%d_%H-%M-%S') + '.sql', shell=True)
            else :
                subprocess.run(extract_folder + '/bin/mysql/bin/mysqldump -u root -proot cerba backup_tracabilite > ' + records_traca_path + '/' + records_prefix + synchronizing_time[0].strftime('%Y-%m_%B') + '.sql', shell=True)
            secondQuery = 'DELETE FROM `tracabilite` WHERE `date heure synchronisation` BETWEEN \'' + synchronizing_time[0].strftime('%Y-%m') + '-01-00:00:00\' AND \'' + synchronizing_time[0].strftime('%Y-%m') + '-31-23:59:59\''
            mycursor.execute(secondQuery)
            mycursor.execute('TRUNCATE `backup_tracabilite`')
            mydb.commit()

        mycursor.close()
        mydb.close()
    except Exception as e :
        canvas1.itemconfigure(displayed_backup_signal, text= 'Intervalle : ' + type_backup_frequence + '\nFréquence : ' + str(interval_backup_time) + '\nErreur à :\n' +  datetime.now().strftime('%d/%m/%Y à %H:%M:%S') + '\n' + str(e), fill='orange')
        

# cette fonction sert de switch au service backup en activant ou désactivant la tache planifiée + en mettant à jour l'affichage
def start_stop_backup() :
    global backup_status
    if (backup_status or web_server_status) :
        backup_status = not backup_status
        if backup_status :
            canvas1.itemconfigure(led_backup_signal, fill='green')
            canvas1.itemconfigure(displayed_backup_signal, text='Intervalle : ' + type_backup_frequence + '\nFréquence : ' + str(interval_backup_time) + '\nService de sauvegarde\nen marche\nDernière sauvegarde :\n', fill='green')
            backup_scheduler.resume()
        else :
            canvas1.itemconfigure(led_backup_signal, fill='red')
            canvas1.itemconfigure(displayed_backup_signal, text='Intervalle : ' + type_backup_frequence + '\nFréquence : ' + str(interval_backup_time) + '\nService de sauvegarde\nà l\'arrêt', fill='red')
            backup_scheduler.pause()
    else :
        messagebox.showerror(title='Serveur web éteint', message='Veuillez allumer le serveur web\npour activer la sauvegarde automatique')

def install() :
    os.makedirs(extract_folder, exist_ok=True)
    if not os.listdir(extract_folder) :
        if os.path.isfile('bin/' + zip_file) :
            global textProgressBar
            textProgressBar = canvas1.create_text(325,15, anchor='w', text='Installation en cours')
            global pb
            pb = ttk.Progressbar(root, orient='horizontal', mode='determinate', length=250)
            global progressBar
            progressBar = canvas1.create_window(450,35,window=pb)
            t1 = threading.Thread(target=displayPb(1,600))
            t2 = threading.Thread(target=install_server)
            t1.start()
            t2.start()
        else :
            messagebox.showerror('Problème de fichier', 'Le fichier MAMP.zip est introuvable,\nVérifiez qu\'il est bien présent.')

    else :
        messagebox.showerror('Serveur déjà installé', 'Le serveur est déjà installé, \ns\'il ne fonctionne pas corectement, appuyez sur Réparer')
    

def displayPb(start, stop) :
    while pb['value'] < 95 :
        pb['value'] += 0.5
        root.update()
        time.sleep(random.randrange(start,stop)/1000)


def install_server() :
    shutil.unpack_archive('bin/' + zip_file, extract_folder) # On extrait l'archive du serveur
    os.chdir(extract_folder)
    path = os.getcwd()
    path_w_slash = path.replace('\\','/')
    # Cette partie modifie le fichier conf du serveur apache pour adapter les chemins d'accès
    with open(apache_file_path, 'r') as conf_file :
        conf_file_data = conf_file.read()
        
    conf_file_data = conf_file_data.replace(default_path, path_w_slash)   # On remplace les chemins d'accès
    conf_file_data = conf_file_data.replace(default_antislash_path, path) # par ceux de l'ordinateur

    with open(apache_file_path, 'w') as conf_file :
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

    canvas1.delete(progressBar)
    canvas1.delete(textProgressBar)

    messagebox.showinfo('Installation réussie','Le serveur est désormais installé')


def repair() :
    safety_msg = messagebox.askyesno('Réparer le serveur', 'Etes-vous sûr de vouloir le réparer ?\nCela le réinitialisera et les données non sauvegardées seront perdues')
    if safety_msg :
        stop_all()
        if os.path.isdir(extract_folder) :
            global textProgressBar
            textProgressBar = canvas1.create_text(325,15, anchor='w', text='Désinstallation en cours')
            global pb
            pb = ttk.Progressbar(root, orient='horizontal', mode='determinate', length=250)
            global progressBar
            progressBar = canvas1.create_window(450,35,window=pb)
            t1 = threading.Thread(target=displayPb(1,450))
            t2 = threading.Thread(target=uninstall_server(showMessage=False))
            t1.start()
            t2.start()
        install()
    
def uninstall() :
    safety_msg = messagebox.askyesno('Désinstaller le serveur', 'Etes-vous sûr de vouloir le désinstaller ?')
    if safety_msg :
        stop_all()
        if os.path.isdir(extract_folder) :
            global textProgressBar
            textProgressBar = canvas1.create_text(325,15, anchor='w', text='Désinstallation en cours')
            global pb
            pb = ttk.Progressbar(root, orient='horizontal', mode='determinate', length=250)
            global progressBar
            progressBar = canvas1.create_window(450,35,window=pb)
            t1 = threading.Thread(target=displayPb(1,450))
            t2 = threading.Thread(target=uninstall_server)
            t1.start()
            t2.start()
        else :
            messagebox.showerror('Serveur non présent', 'Le serveur n\'était pas présent au chemin d\'accès spécifié')

def uninstall_server(showMessage = True) :
    shutil.rmtree(extract_folder, ignore_errors=True)
    if showMessage : messagebox.showinfo('Désinstallation réussie','Le serveur a été désinstallé')
    canvas1.delete(textProgressBar)
    canvas1.delete(progressBar)


def quit() :
    stop_all()
    root.destroy()


def disable_event() :
    pass

def start_stop_web_server() :
    global web_server_status
    if os.path.isfile(extract_folder + '/MAMP.exe') or web_server_status :
        web_server_status = not web_server_status
        if (web_server_status) :
            launch_server()
            cleaning_box_scheduler.resume()
        else :
            stop_server()
            cleaning_box_scheduler.pause()
            stop_all()
    else :
        messagebox.showerror('Impossible de lancer le serveur', 'Serveur introuvable.\nVeuillez réessayer ou appuyer sur Réparer')

def launch_server() :
    
        try : 
            subprocess.call('powershell Start-Process -FilePath ' + extract_folder + '/MAMP.exe -WindowStyle Minimized', creationflags=subprocess.CREATE_NO_WINDOW) 
            canvas1.itemconfigure(led_web_signal, fill='green')
            success_text = 'Serveur démarré le ' + datetime.now().strftime('%d/%m/%Y à %H:%M:%S') + '\nà l\'adresse ' + ip
            canvas1.itemconfigure(displayed_web_signal, text=success_text, fill='green')

        except ValueError: 
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


def open_phpMyAdmin() :
    if not subprocess.call('powershell get-process mamp -errorAction SilentlyContinue', creationflags=subprocess.CREATE_NO_WINDOW) :
        webbrowser.open('http://localhost/phpMyAdmin/')
    
    else :
        messagebox.showerror('Serveur non démarré', 'Le serveur n\'est pas démarré,\nappuyez d\'abord sur Démarrer le serveur')


def launch_all() :
    global web_server_status
    if not web_server_status : start_stop_web_server()
    global pda_status
    if not pda_status : start_stop_pda()
    global backup_status
    if not backup_status : start_stop_backup()
    global reception_status
    if not reception_status : start_stop_reception()


def stop_all() :
    global pda_status
    if pda_status : start_stop_pda()
    global backup_status
    if backup_status : start_stop_backup()
    global reception_status
    if reception_status : start_stop_reception()
    global web_server_status
    if web_server_status : start_stop_web_server()


def stop_process() :
    global web_server_status
    web_server_status = False
    canvas1.itemconfigure(led_web_signal, fill='red')
    canvas1.itemconfigure(displayed_web_signal, text='Serveur web à l\'arrêt', fill='red')
    subprocess.run('taskkill /IM httpd.exe /IM mysqld.exe /IM MAMP.exe /F')


def open_variables_file() :
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    subprocess.run('powershell start bin/variables.txt', creationflags=subprocess.CREATE_NO_WINDOW)


def import_backup() :
    if (web_server_status) :
        backup(changeDisplay=False)
        filename = fd.askopenfilename(filetypes=(('fichier sql', '*.sql'),('tous les fichiers', '*.*')))
        if (len(filename) > 0) :
            try :
                subprocess.run(extract_folder + '/bin/mysql/bin/mysql -u root -proot cerba < "' + filename + '"', shell=True)
                messagebox.showinfo(title='Importation réussie', message='L\'importation du fichier ' + filename.split('/')[-1] + ' est terminée')
            except Exception as e:
                messagebox.showerror(title='Impossible d\'importer le fichier', message=str(e))
    else :
        messagebox.showerror(title='Serveur web éteint', message='Veuillez allumer le serveur web\npour importer la base de données')


# cette fonction sert de switch au service reception en activant ou désactivant la tache planifiée + en mettant à jour l'affichage
def start_stop_reception() :
    global reception_status
    if (web_server_status or reception_status) :
        reception_status = not reception_status
        if reception_status :
            canvas1.itemconfigure(led_reception_signal, fill='green')
            canvas1.itemconfigure(displayed_reception_signal, text='Intervalle : ' + type_reception_frequence + '\nFréquence : ' + str(reception_frequence) + '\nService réception en marche\nDernière synchronisation :\n', fill='green')
            reception_scheduler.resume()
        else :
            canvas1.itemconfigure(led_reception_signal, fill='red')
            canvas1.itemconfigure(displayed_reception_signal, text='Intervalle : ' + type_reception_frequence + '\nFréquence : ' + str(reception_frequence) + '\nService réception à l\'arrêt', fill='red')
            reception_scheduler.pause()
    else :
        messagebox.showerror(title='Serveur web éteint', message='Veuillez allumer le serveur web\npour activer le service réception')


# cette fonction est répétée périodiquement et réecrit un fichier contenant une boite par ligne en ajoutant la dernière réception de la boite
def reception() :
    os.makedirs(last_reception_in_directory, exist_ok=True)
    mydb = mysql.connector.connect(host='localhost', user='root', password='root', database='cerba')
    mycursor = mydb.cursor(buffered=True)
    file_names = os.listdir(last_reception_in_directory)
    try :
        for file_name in file_names :
            with open(last_reception_in_directory + '/' + file_name, 'r') as in_file :
                with open(last_reception_out_directory + '/' + file_name, 'w') as out_file :
                    file_data = in_file.read()
                    file_data = file_data.splitlines()
                    for data in file_data :
                        box = data[20:]
                        query = 'SELECT `DATE HEURE ENREGISTREMENT` FROM `tracabilite` WHERE `BOITE` = "' + box.strip() + '" AND `ACTION` = "VIT" ORDER BY `DATE HEURE ENREGISTREMENT` DESC LIMIT 1'
                        mycursor.execute(query)
                        registering_time = mycursor.fetchone()
                        if registering_time is not None :
                            result = registering_time[0].strftime('Heure de réception : %Hh%M le %d/%m/%Y')
                            out_file.write(data.ljust(40) + result + '\n')
                        else :
                            out_file.write(data + '\n')
            os.remove(last_reception_in_directory + '/' + file_name)
        canvas1.itemconfigure(displayed_reception_signal, text='Intervalle : ' + type_reception_frequence + '\nFréquence : ' + str(reception_frequence) + '\nService réception en marche\nDernière synchronisation :\n' +  datetime.now().strftime('%d/%m/%Y à %H:%M:%S'), fill='green')
    except Exception as e :
        canvas1.itemconfigure(displayed_reception_signal, text= 'Intervalle : ' + type_reception_frequence + '\nFréquence : ' + str(reception_frequence) + '\nErreur à :\n' +  datetime.now().strftime('%d/%m/%Y à %H:%M:%S') + '\n' + str(e), fill='orange')

    mycursor.close()
    mydb.close()

def clean_boxes() :
    if (web_server_status) :
        try :
            mydb = mysql.connector.connect(host='localhost', user='root', password='root', database='cerba')
            mycursor = mydb.cursor()
            mycursor.execute('DELETE FROM `tube`')
            mydb.commit()
            mycursor.execute('DELETE FROM `boite` WHERE `TYPE BOITE` = "SAC"')
            mydb.commit()
            mycursor.close()
            mydb.close()
        except Exception as e :
            messagebox.showerror(title='Problème du vidage automatique des boîtes', message='Impossible de vider automatiquement les boîtes. Cette erreur a été rencontrée : ' + str(e))

global ip
ip = socket.gethostbyname(socket.gethostname())

global pda_status
pda_status = False

global web_server_status
web_server_status = False

global backup_status
backup_status = False

global reception_status
reception_status = False

pda_scheduler = BackgroundScheduler()
pda_scheduler.add_job(import_traca_pda, 'cron', minute=minute_synchro_pda_1, timezone='Europe/Berlin')
pda_scheduler.add_job(import_traca_pda, 'cron', minute=minute_synchro_pda_2, timezone='Europe/Berlin')
pda_scheduler.start(paused=True)

cleaning_box_scheduler = BackgroundScheduler()
cleaning_box_scheduler.add_job(clean_boxes, 'cron', hour=cleaning_hour, timezone='Europe/Berlin')
cleaning_box_scheduler.start(paused=True)

backup_scheduler = BackgroundScheduler()
if (type_backup_frequence == 'seconde') :
    backup_scheduler.add_job(backup, 'interval', seconds=interval_backup_time, timezone='Europe/Berlin')
elif (type_backup_frequence == 'minute') :
    backup_scheduler.add_job(backup, 'interval', minutes=interval_backup_time, timezone='Europe/Berlin')
elif (type_backup_frequence == 'heure') :
    backup_scheduler.add_job(backup, 'interval', hours=interval_backup_time, timezone='Europe/Berlin')
elif (type_backup_frequence == 'jour') :
    backup_scheduler.add_job(backup, 'interval', days=interval_backup_time, timezone='Europe/Berlin')    
backup_scheduler.start(paused=True)

reception_scheduler = BackgroundScheduler()
if (type_reception_frequence == 'seconde') :
    reception_scheduler.add_job(reception, 'interval', seconds=reception_frequence, timezone='Europe/Berlin')
elif (type_reception_frequence == 'minute') :
    reception_scheduler.add_job(reception, 'interval', minutes=reception_frequence, timezone='Europe/Berlin')
elif (type_reception_frequence == 'heure') :
    reception_scheduler.add_job(reception, 'interval', hours=reception_frequence, timezone='Europe/Berlin')
elif (type_reception_frequence == 'jour') :
    reception_scheduler.add_job(reception, 'interval', days=reception_frequence, timezone='Europe/Berlin')
reception_scheduler.start(paused=True)   


root= tk.Tk(className='Serveur de colisage')
root.protocol('WM_DELETE_WINDOW', disable_event) # désactive la croix de fermeture Windows
root.iconbitmap('bin/Cerba.ico')
canvas1 = tk.Canvas(root, width = 900, height = 500, background= '#E1F5FE')
canvas1.pack()

windll.shcore.SetProcessDpiAwareness(1)

launch_all_button = tk.Button(text='Démarrer tous\nles services', command=launch_all, bg='green', fg='white')
canvas1.create_window(150,50, window=launch_all_button)

stop_all_button = tk.Button(text='Arrêter tous\nles services', command=stop_all, bg='brown', fg='white')
canvas1.create_window(150,100, window=stop_all_button)

open_website_button = tk.Button(text='Accéder au\nsite web', command=open_website, bg='blue', fg='white')
canvas1.create_window(450, 75, window=open_website_button)

open_website_button = tk.Button(text='Ouvrir le fichier\nconfig', command=open_variables_file, bg='black', fg='white')
canvas1.create_window(750, 50, window=open_website_button)

open_phpMyAdmin_button = tk.Button(text='Administrer la\nbase de données', command=open_phpMyAdmin, bg='black', fg='white')
canvas1.create_window(750, 100, window=open_phpMyAdmin_button)

quit_button = tk.Button(text='Quitter', command=quit, bg='brown', fg='white')
canvas1.create_window(870,20, window=quit_button)

canvas1.create_line(50,150,850,150) # première ligne horizontale

pda_title = canvas1.create_text(110,170, anchor='center', text='Réception PDA', font='Helvetica 13 bold')

led_pda_signal = canvas1.create_oval(10,190,30,210, fill='red')
displayed_pda_signal = canvas1.create_text(10,230, width=210, anchor= 'nw', text='Programmation : chaque heure à ' + str(minute_synchro_pda_1) + ' et ' + str(minute_synchro_pda_2) + '\nService PDA à l\'arrêt', fill='red')

pda_button = tk.Button(text='Activer/Désactiver la\nréception des fichiers PDA', command=start_stop_pda, bg='black', fg='white')
pda_window = canvas1.create_window(110, 380, window=pda_button)

canvas1.create_line(225,180,225,400) # première ligne verticale

web_title = canvas1.create_text(325,170, anchor='center', text='Serveur web', font='Helvetica 13 bold')

led_web_signal = canvas1.create_oval(235,190,255,210, fill='red')
displayed_web_signal = canvas1.create_text(235,230, width=200, anchor= 'nw', text='Serveur web à l\'arrêt', fill='red')

web_server_button = tk.Button(text='Démarrer/Arrêter \nle serveur web', command=start_stop_web_server, bg='black', fg='white')
canvas1.create_window(290, 380, window=web_server_button)

stop_process_button = tk.Button(text='Arrêt forcé', command=stop_process, bg='brown', fg='white')
canvas1.create_window(390,380,window=stop_process_button)

canvas1.create_line(450,180,450,400) # deuxième ligne verticale

backup_title = canvas1.create_text(560,170, anchor='center', text='Sauvegarde automatique', font='Helvetica 13 bold')

led_backup_signal = canvas1.create_oval(460,190,480,210, fill='red')
displayed_backup_signal = canvas1.create_text(460,230, width=200, anchor= 'nw', text='Intervalle : ' + type_backup_frequence + '\nFréquence : ' + str(interval_backup_time) + '\nService sauvegarde à l\'arrêt', fill='red')

backup_button = tk.Button(text='Activer/Désactiver\nla sauvegarde\nautomatique', command=start_stop_backup, bg='black', fg='white')
canvas1.create_window(510,380, window=backup_button)

database_button = tk.Button(text='Importer la \nbase de données', command=import_backup, bg='black', fg='white')
canvas1.create_window(620,380, window=database_button)

canvas1.create_line(675,180,675,400) # troisième ligne verticale

reception_title = canvas1.create_text(770,170, anchor='center', text='Réception boites', font='Helvetica 13 bold')

led_reception_signal = canvas1.create_oval(685,190,705,210, fill='red')
displayed_reception_signal = canvas1.create_text(685,230, width=220, anchor= 'nw', text='Intervalle : ' + type_reception_frequence + '\nFréquence : ' + str(reception_frequence) + '\nService réception à l\'arrêt', fill='red')

reception_button = tk.Button(text='Activer/Désactiver le\nservice réception', command=start_stop_reception, bg='black', fg='white')
reception_window = canvas1.create_window(770, 380, window=reception_button)

canvas1.create_line(50,420,850,420) # deuxième ligne horizontale

install_button = tk.Button(text='Installer le serveur',command=install, bg='green',fg='white')
canvas1.create_window(100, 460, window=install_button)

repair_button = tk.Button(text='Réparer le serveur', command=repair, bg='brown', fg='white')
canvas1.create_window(450, 460, window=repair_button)

uninstall_button = tk.Button(text='Désinstaller le serveur', command=uninstall, bg='red', fg='white')
canvas1.create_window(800, 460, window=uninstall_button)







root.mainloop()