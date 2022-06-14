import os
import shutil
import tkinter as tk
from tkinter import messagebox
from ctypes import windll
from datetime import datetime
import webbrowser
import socket
import subprocess

# Toutes les variables en dur
zip_file = 'MAMP.zip'
extract_folder = 'MAMP'
conf_file_path = 'MAMP/conf/apache/httpd.conf'
default_path = 'directoryPathSlash'
default_antislash_path = 'directoryPathAntiSlash'
main_file_path = 'MAMP/htdocs/main.dart.js'
default_ip = 'default_ip'
my_file_path = 'MAMP/conf/mysql/my.ini'
php_file_path = 'MAMP/conf/php7.4.1/php.ini'

path = os.getcwd()
path_w_slash = path.replace('\\','/')
global ip
ip = socket.gethostbyname(socket.gethostname())


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
    stop_server()
    root.destroy()


def disable_event() :
    pass


def launch_server() :
    if os.path.isfile(extract_folder + '/MAMP.exe') :
        try : 
            subprocess.call('powershell Start-Process -FilePath ' + extract_folder + '/MAMP.exe -WindowStyle Minimized', creationflags=subprocess.CREATE_NO_WINDOW) 
            canvas1.itemconfigure(led_signal, fill='green')
            success_text = 'Serveur démarré le ' + datetime.now().strftime('%d/%m/%Y à %H:%M:%S') + '\nà l\'adresse ' + ip
            canvas1.itemconfigure(displayed_signal, text=success_text, fill='green')

        except ValueError: 
            messagebox.showerror('Impossible de lancer le serveur', 'Impossible de lancer le serveur.\nVeuillez réessayer ou appuyer sur Réparer')

    else :
        messagebox.showerror('Impossible de lancer le serveur', 'Impossible de lancer le serveur.\nVeuillez réessayer ou appuyer sur Réparer')


def stop_server() :
    subprocess.call('powershell if (get-process mamp -ErrorAction SilentlyContinue){(get-process mamp).closeMainWindow()}', creationflags=subprocess.CREATE_NO_WINDOW)
    canvas1.itemconfigure(led_signal, fill='red')
    canvas1.itemconfigure(displayed_signal, text='Serveur à l\'arrêt', fill='red')


def open_website() :
    if not subprocess.call('powershell get-process mamp -errorAction SilentlyContinue', creationflags=subprocess.CREATE_NO_WINDOW) :
        webbrowser.open('http://' + ip)
    
    else :
        messagebox.showerror('Serveur non démarré', 'Le serveur n\'est pas démarré,\nappuyez d\'abord sur Démarrer le serveur')


root= tk.Tk(className='Serveur CerbaTraça')
root.protocol('WM_DELETE_WINDOW', disable_event) # désactive la croix de fermeture Windows
root.iconbitmap('Cerba.ico')
canvas1 = tk.Canvas(root, width = 500, height = 400)
canvas1.pack()

windll.shcore.SetProcessDpiAwareness(1)

install_button = tk.Button(text='Installer le serveur',command=install, bg='green',fg='white')
canvas1.create_window(100, 350, window=install_button)

repair_button = tk.Button(text='Réparer le serveur', command=repair, bg='brown', fg='white')
canvas1.create_window(250, 350, window=repair_button)

uninstall_button = tk.Button(text='Désinstaller le serveur', command=uninstall, bg='red', fg='white')
canvas1.create_window(400, 350, window=uninstall_button)

quit_button = tk.Button(text='Quitter', command=quit, bg='grey', fg='white')
canvas1.create_window(470,20, window=quit_button)

run_server_button = tk.Button(text='Démarrer \nle serveur', command=launch_server, bg='green', fg='white')
canvas1.create_window(100, 150, window=run_server_button)

stop_server_button = tk.Button(text='Arrêter \nle serveur', command=stop_server, bg='brown', fg='white')
canvas1.create_window(400, 150, window=stop_server_button)

open_website_button = tk.Button(text='Accéder\nau\nsite web', command=open_website, bg='blue', fg='white')
canvas1.create_window(250, 150, window=open_website_button)

led_signal = canvas1.create_oval(50,20,70,40, fill='red')
displayed_signal = canvas1.create_text(90,30, anchor= 'w', text='Serveur à l\'arrêt', fill='red')

root.mainloop()