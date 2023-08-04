import tkinter as tk
from tkinter import ttk
import threading

from prepare_server import perpare_server

def do_the_thing(version):
    loading_spinner.config(mode="indeterminate")
    loading_spinner.start()

    button.config(state=tk.DISABLED)
    try:
        perpare_server(version)
    except:
        pass
    button.config(state=tk.NORMAL)

    loading_spinner.stop()
    loading_spinner.config(mode="determinate")

def on_button_click():
    thread = threading.Thread(target=do_the_thing, args=(text_entry.get(),))
    thread.start()

# Create the main application window
root = tk.Tk()
root.title("Magic Minecrafterer!")

label = tk.Label(root, text="Minecraft version:")
text_entry = tk.Entry(root)
button = tk.Button(root, text="Download", command=on_button_click)
loading_spinner = ttk.Progressbar(root, mode="determinate", value=0)

# Grid layout for widgets
label.grid(row=0, column=0, padx=10, pady=10)
text_entry.grid(row=0, column=1, padx=10, pady=10)
button.grid(row=1, column=0, columnspan=2, padx=10, pady=10)
loading_spinner.grid(row=2, column=0, columnspan=2, padx=10, pady=10)

# Start the main event loop
root.mainloop()
