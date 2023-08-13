import glob
import threading
import tkinter as tk
from tkinter import ttk

from prepare_server import perpare_server
from upload_server import upload_server


def prepare(version, resource_pack):
    prepare_loading_spinner.config(mode="indeterminate")
    prepare_loading_spinner.start()

    prepare_button.config(state=tk.DISABLED)
    path = None
    try:
        path = perpare_server(version, resource_pack)
    except:
        pass
    prepare_button.config(state=tk.NORMAL)
    folder_entry.set_menu(*glob.glob('tmp_*[!.zip]'))

    if path:
        folder_value.set(path)
        upload_button.config(state=tk.NORMAL)

    prepare_loading_spinner.stop()
    prepare_loading_spinner.config(mode="determinate")

def upload(tag, folder):
    if not tag:
        return
    
    upload_loading_spinner.config(mode="indeterminate")
    upload_loading_spinner.start()

    upload_button.config(state=tk.DISABLED)
    try:
        upload_server(tag, folder)
    except:
        pass
    upload_button.config(state=tk.NORMAL)

    upload_loading_spinner.stop()
    upload_loading_spinner.config(mode="determinate")

def on_prepare_button_click():
    thread = threading.Thread(target=prepare, args=(version_entry.get(), resource_pack_entry.get()))
    thread.start()

def on_upload_button_click():
    thread = threading.Thread(target=upload, args=(tag_entry.get(), folder_value.get()))
    thread.start()

# Create the main application window
root = tk.Tk()
root.title("Magic Minecrafterer!")

version_label = tk.Label(root, text="Minecraft version:")
version_entry = tk.Entry(root)
resource_pack_label = tk.Label(root, text="Custom resource pack (leave empty if no):")
resource_pack_entry = tk.Entry(root)
prepare_button = tk.Button(root, text="Download", command=on_prepare_button_click)
prepare_loading_spinner = ttk.Progressbar(root, mode="determinate", value=0)

tag_label = tk.Label(root, text="Tag (MUST be unique or will overwrite):")
tag_entry = tk.Entry(root)
folder_label = tk.Label(root, text="Folder:")
folder_value = tk.StringVar(root)
folder_options = glob.glob('tmp_*[!.zip]')
folder_value.set("No folders found" if len(folder_options) == 0 else folder_options[0])
folder_entry = ttk.OptionMenu(root, folder_value, *folder_options)
upload_button = tk.Button(root, text="Upload", command=on_upload_button_click, state=tk.DISABLED if len(folder_options) == 0 else tk.NORMAL)
upload_loading_spinner = ttk.Progressbar(root, mode="determinate", value=0)

# Grid layout for widgets
version_label.grid(row=0, column=0, padx=10, pady=10)
version_entry.grid(row=0, column=1, padx=10, pady=10)
resource_pack_label.grid(row=1, column=0, padx=10, pady=10)
resource_pack_entry.grid(row=1, column=1, padx=10, pady=10)
prepare_button.grid(row=2, column=0, columnspan=2, padx=10, pady=10)
prepare_loading_spinner.grid(row=3, column=0, columnspan=2, padx=10, pady=10)

tag_label.grid(row=4, column=0, padx=10, pady=10)
tag_entry.grid(row=4, column=1, padx=10, pady=10)
folder_label.grid(row=5, column=0, padx=10, pady=10)
folder_entry.grid(row=5, column=1, padx=10, pady=10)
upload_button.grid(row=6, column=0, columnspan=2, padx=10, pady=10)
upload_loading_spinner.grid(row=7, column=0, columnspan=2, padx=10, pady=10)

# Start the main event loop
root.mainloop()
