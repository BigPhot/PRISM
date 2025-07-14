import sys
from PySide6.QtCore import QUrl, QObject, Slot, Signal, Property, QAbstractListModel, Qt, QModelIndex
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtWidgets import QApplication
from PySide6.QtQml import QmlElement
import os
from backend.Tasks import create_task, expand_step, combine_steps, delete_step, log_time, add_context, add_step, move_task, move_tasks_category, move_step, set_tasks_file
from backend.Graph import graph_nodes_creation
import json 
import pandas as pd
from datetime import date, datetime
import math

"""
Configures QML module information and determines base directory for task and image file paths.

Constants:
QML_IMPORT_NAME (str): QML module identifier.
QML_IMPORT_MAJOR_VERSION (int): Major version of the QML module.
BASE_DIR (str): The root path of the application, adjusted for PyInstaller bundling.
TASK_FILES (list): List of JSON file paths for different task datasets.
TITLE_IMAGES (list): List of image file paths for application titles.
"""
# Define module name and version for QML
QML_IMPORT_NAME = "io.qt.dynamicmenu"
QML_IMPORT_MAJOR_VERSION = 1

if getattr(sys, 'frozen', False):
    # Running inside PyInstaller bundle (EXE)
    BASE_DIR = os.path.dirname(sys.executable)  # EXE's folder
else:
    # Running normally (script)
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

TASK_FILES = [
    os.path.join(BASE_DIR, "data", "Prism_Task_Data.json"),
    os.path.join(BASE_DIR, "data", "LeJarvis_Task_Data.json"),
    os.path.join(BASE_DIR, "data", "ImBored_Task_Data.json"),
    os.path.join(BASE_DIR, "data", "Doctrine_Task_Data.json"),
    os.path.join(BASE_DIR, "data", "Masters_Task_Data.json")
]

TITLE_IMAGES = [
    "./images/PRISM_title.png",
    "./images/LeJarvis_title.png",
    "./images/Bored_title.png",
    "./images/Doctrine_title.png",
    "./images/Masters_title.png"
]

@QmlElement
class MenuBackend(QObject):
    """
    Initializes the MenuBackend QML bridge class.

    - Sets up the active task file and loads all tasks.
    - Filters tasks into categories: 'idea', 'dev', and 'rlty'.
    - Initializes the submenu with steps from the first development task.
    - Sets the default selected menu index.

    Signals:
        menuItemsChanged: Emitted when top-level menu items are updated.
        submenuItemsChanged: Emitted when submenu items change.
    """
    menuItemsChanged = Signal()
    submenuItemsChanged = Signal()

    def __init__(self):
        super().__init__()
        self._task_index = 0  # Track which file is currently active
        self._tasks_file = TASK_FILES[self._task_index]

        all_tasks = self.loadTasks()
        self._idea_menu_items = [item for item in all_tasks if item.get("category") == "idea"]
        self._dev_menu_items = [item for item in all_tasks if item.get("category") == "dev"]
        self._rlty_menu_items = [item for item in all_tasks if item.get("category") == "rlty"]

        # Default submenu and selection
        self._submenu_items = self._dev_menu_items[0]["steps"] if self._dev_menu_items else []
        self._selected_menu_index = 0


    def loadTasks(self):
        """
        Load tasks from the currently selected JSON file.

        Returns:
            list: A list of task dictionaries loaded from the JSON file.
                Returns an empty list if the file doesn't exist, is empty, or is corrupted.
        """

        if os.path.exists(self._tasks_file):
            with open(self._tasks_file, "r", encoding="utf-8") as file:
                try:
                    tasks = json.load(file)  # Load existing tasks
                    return tasks if isinstance(tasks, list) else []
                except json.JSONDecodeError:
                    return []  # If file is empty or corrupted, return empty list
        return []
    
    def getMenuListbyCategory(self, category):
        """
        Retrieve the list of menu items based on the provided category.

        Parameters:
            category (str): The category of tasks ('idea', 'dev', or 'rlty').

        Returns:
            list: A list of tasks matching the category, or an empty list if the category is unknown.
        """
        if category == "idea":
            return self._idea_menu_items
        elif category == "dev":
            return self._dev_menu_items
        elif category == "rlty":
            return self._rlty_menu_items
        return []
    
    @Property(str, notify=menuItemsChanged)
    def currentTaskFile(self):
        """Get the file path of the currently active task JSON file."""
        return self._tasks_file

    @Slot(int)
    def cycleTaskFile(self, index):
        """
        Cycles through the list of task files, updates the current task file path,
        sets it globally via `set_tasks_file`, and refreshes the menu data accordingly.
        """
        #self._task_index = (self._task_index + 1) % len(TASK_FILES)
        self._tasks_file = TASK_FILES[index]
        set_tasks_file(self._tasks_file)
        self.refreshMenu()
   
    @Slot(int, str)
    def setSelectedMenuIndex(self, index, category):
        """
        Set the selected menu index for a given category.

        Parameters:
        index (int): The index to select in the specified category's menu list.
        category (str): The category name ('idea', 'dev', or 'rlty').

        Emits:
        submenuItemsChanged: Signal emitted when the submenu selection changes.
        """
        target_list = self.getMenuListbyCategory(category)
        if 0 <= index < len(target_list):
            self._selected_menu_index = index
            self.submenuItemsChanged.emit()

    @Slot(str, result="QVariantMap")
    def getCurrentMenuDetails(self, category):
        """
        Retrieve the title and description of the currently selected menu item in the given category.

        Parameters:
        category (str): The category name ('idea', 'dev', or 'rlty').

        Returns:
        dict: A dictionary with 'title' and 'description' of the selected menu item, or empty strings if the index is out of range.
        """
        menu_list = self.getMenuListbyCategory(category)
        if 0 <= self._selected_menu_index < len(menu_list):
            selected_menu = menu_list[self._selected_menu_index]
            return {
                "title": selected_menu["title"],
                "description": selected_menu["description"]
            }
        return {"title": "", "description": ""}

    @Property(int, notify=menuItemsChanged)
    def selectedMenuIndex(self):
        """Return the index of the selected menu item."""
        return self._selected_menu_index

    @Property(list, notify=menuItemsChanged)
    def IdeaMenuItems(self):
        """Expose menu items as a property to QML."""
        return self._idea_menu_items
    
    @Property(list, notify=menuItemsChanged)
    def DevMenuItems(self):
        """Expose menu items as a property to QML."""
        return self._dev_menu_items
    
    @Property(list, notify=menuItemsChanged)
    def RltyMenuItems(self):
        """Expose menu items as a property to QML."""
        return self._rlty_menu_items
    
    @Property(list, notify=submenuItemsChanged)
    def SubMenuItems(self):
        """Return the list of menu items to QML."""
        return self._submenu_items
    
    @Property(str, notify=menuItemsChanged)
    def currentTitleImage(self):
        """Return the current title image"""
        return TITLE_IMAGES[self._task_index]

    @Slot(int, str)
    def updateSubMenuItems(self, index, category):
        """Update the submenu items based on selected index and category."""
        target_list = self.getMenuListbyCategory(category)

        if 0 <= index < len(target_list):
            self._submenu_items = target_list[index]["steps"]
            self.submenuItemsChanged.emit()


    @Slot()
    def refreshMenu(self):
        """Reload tasks from file and update categorized lists."""
        all_tasks = self.loadTasks()
        self._menu_items = all_tasks  # Optional: keep for backward compatibility
        # Categorize tasks
        self._idea_menu_items = [task for task in all_tasks if task.get("category") == "idea"]
        self._dev_menu_items = [task for task in all_tasks if task.get("category") == "dev"]
        self._rlty_menu_items = [task for task in all_tasks if task.get("category") == "rlty"]
        # Reset submenu to first item in each, if needed
        self._selected_menu_index = 0
        self._submenu_items = (
            self._dev_menu_items[0]["steps"]
            if self._dev_menu_items else []
        )
        self.menuItemsChanged.emit()
        self.submenuItemsChanged.emit()

    @Slot(int, int, str)
    def moveTask(self, fromIndex, toIndex, category):
        """Move a task within the specified category from one index to another."""
        if (category == 'idea'):
            tasks = self.IdeaMenuItems
        elif ( category == 'dev'):
            tasks = self.DevMenuItems
        elif ( category == 'rlty'):
            tasks = self.RltyMenuItems
        move_task(tasks, fromIndex, toIndex, category)
        self.refreshMenu()


    @Slot(str, int, str)
    def moveTaskToCategory(self, fromCategory, index, toCategory):
        """Move a task from one category to another and refresh the menu."""

        move_tasks_category(fromCategory, index, toCategory)
        self.refreshMenu()

    @Slot(int, int)
    def moveStep(self, from_index, to_index):
        """
        Move a step within the current submenu and refresh the menu.

        Parameters:
        from_index (int): The original index of the step to move.
        to_index (int): The target index to move the step to.
        """
        move_step(
            self._submenu_items,
            self._dev_menu_items,
            self._selected_menu_index,
            from_index,
            to_index,
        )
        self.refreshMenu()

    @Slot(list, str, str)
    def combineSteps(self, stepDescriptions, parentTitle, parentDescription):  
        """
        Combine multiple steps into a single parent step and refresh the menu.

        Parameters:
        stepDescriptions (list of str): Descriptions of the steps to combine.
        parentTitle (str): Title of the new combined step.
        parentDescription (str): Description of the new combined step.
        """
        steps_data = {
            "title": parentTitle,
            "description": parentDescription,
            "steps_to_combine": stepDescriptions 
        }
        combine_steps(steps_data)
        self.refreshMenu()

    @Slot(str, str, str)
    def expandStep(self, stepDescription, parentTitle, parentDescription):
        """
        Expand a single step into multiple sub-steps and refresh the menu.

        Parameters:
        stepDescription (str): Description of the step to expand.
        parentTitle (str): Title of the parent step.
        parentDescription (str): Description of the parent step.
        """
        step_data = {
        "title": parentTitle,
        "description": parentDescription,
        "step_to_expand": stepDescription
        }
        expand_step(step_data)
        self.refreshMenu()

    @Slot(str, str, str)
    def deleteStep(self, stepDescription, parentTitle, parentDescription):
        """
        Delete a specific step from a parent task and refresh the menu.

        Parameters:
        stepDescription (str): Description of the step to delete.
        parentTitle (str): Title of the parent task.
        parentDescription (str): Description of the parent task.
        """
        step_data = {
            "title": parentTitle,
            "description": parentDescription,
            "step_to_delete": stepDescription
            }
        delete_step(step_data)
        self.refreshMenu()

    @Slot(str, int, str, str)
    def recordStepTime(self, stepDescription, seconds, parentTitle, parentDescription):
        """
        Record the time spent on a specific step within a parent task.

        Parameters:
        stepDescription (str): Description of the step to record time for.
        seconds (int or float): Duration in seconds to log.
        parentTitle (str): Title of the parent task.
        parentDescription (str): Description of the parent task.
        """
        step_data = {
            "project": self._tasks_file,
            "title": parentTitle,
            "description": parentDescription,
            "step_to_record": stepDescription,
            "duration": seconds
            }
        print(step_data)
        log_time(step_data)
    


class Input(QObject):
    """Initialize the Input class, a QObject subclass."""
    def __init__(self):  # Accept external instance
        super().__init__()# Store reference

    @Slot(str)
    def processTaskInput(self, text):
        """
        Process a raw task input string and create a new task.

        Parameters:
        text (str): The raw task text to be processed and added.
        """
        create_task(text)

    @Slot(str, int)
    def processContextInput(self, text, index):
        """
        Add contextual information to a specific task based on user input.

        Parameters:
        text (str): The context text to add.
        index (int): The index of the task to which the context will be added.
        """
        add_context(text, index)

    @Slot(str, int)
    def processStepInput(self, text, index):
        """
        Add a new step to a task based on user input.

        Parameters:
        text (str): The step text to add.
        index (int): The index of the task to which the step will be added.
        """
        add_step(text, index)

class NodeModel(QAbstractListModel):
    XRole = Qt.ItemDataRole.UserRole + 1
    YRole = Qt.ItemDataRole.UserRole + 2
    LabelRole = Qt.ItemDataRole.UserRole + 3
    nodesChanged = Signal()

    def __init__(self, df=None, parent=None):
        super().__init__(parent)
        self.df = df  # Raw activity DataFrame
        self._nodes = []
    
    def update_nodes(self, nodes):
        self.beginResetModel()
        self._nodes = nodes
        self.endResetModel()
        self.nodesChanged.emit()

    def rowCount(self, parent=QModelIndex()):
        return len(self._nodes)

    def data(self, index, role):
        if not index.isValid():
            return None
        node = self._nodes[index.row()]
        if role == self.XRole:
            return node['x']
        elif role == self.YRole:
            return node['y']
        elif role == self.LabelRole:
            return node['label']
        return None

    def roleNames(self):
        return {
            self.XRole: b'x',
            self.YRole: b'y',
            self.LabelRole: b'label'
        }

    @Slot('QDate', 'QDate')
    def onDateChanged(self, start_qdate, end_qdate):
        start_date = datetime(start_qdate.year(), start_qdate.month(), start_qdate.day())
        end_date = datetime(end_qdate.year(), end_qdate.month(), end_qdate.day())
        print(start_date, end_date)
        nodes = graph_nodes_creation(start_date, end_date, 'Prism')
        self.update_nodes(nodes)

    @Slot(int, result='QVariant')
    def get(self, index):
        if 0 <= index < len(self._nodes):
            return self._nodes[index]
        return None

    @Property(int, constant=True)
    def count(self):
        return len(self._nodes)
    
    @Property(int, notify=nodesChanged)
    def scaledMaxY(self):
        if not self._nodes:
            return 0
        raw_max = max(node['y'] for node in self._nodes) * 1.1
        print(raw_max)
        return math.ceil(raw_max / 10) * 10


if __name__ == "__main__":
    """
    Initialize and run the Qt app:

    - Setup PATH for Qt binaries
    - Create app and QML engine
    - Register Python backends
    - Load main QML file and run event loop
    - Handle startup errors
    """

    qt_bin_path = "C:/Qt/Tools/QtDesignStudio/qt6_design_studio_reduced_version/bin"

    # Add it to the PATH environment variable
    os.environ["PATH"] = qt_bin_path + os.pathsep + os.environ.get("PATH", "")
    venv_qt_bin = os.path.join(sys.prefix, "Lib", "site-packages", "PySide6")
    os.environ["PATH"] = venv_qt_bin + os.pathsep + os.environ.get("PATH", "")

    try:
        # Create the application
        app = QApplication(sys.argv)

        # Create the QQmlApplicationEngine instance
        engine = QQmlApplicationEngine()
        

        engine.addImportPath("C:/Users/adhir/Developement/PRISM/IntCont")
        engine.addImportPath("C:/Qt/Tools/QtDesignStudio/qt6_design_studio_reduced_version/qml")
        engine.addImportPath("C:/Qt/6.9.1/mingw_64/include")

        
        # Register the Input class as a context property
        menu_backend = MenuBackend()  # Menu backend
        input_backend = Input()
        #node_model = NodeModel()
        node_model = NodeModel()
        


        engine.rootContext().setContextProperty("submenuBackend", menu_backend)
        engine.rootContext().setContextProperty("inputBackend", input_backend)
        engine.rootContext().setContextProperty("nodeModel", node_model)

        visibleStart = datetime(2025, 5, 19)
        visibleEnd = datetime(2025, 6, 30)
        

        nodes = graph_nodes_creation(visibleStart, visibleEnd, 'Prism')
        
        node_model.update_nodes(nodes)
        

        node_model.nodesChanged.connect(lambda: print("Signal onNodesChanged was emitted!"))
        

        engine.clearComponentCache() 
        # Load the QML file
        print("Loading QML...")
        engine.load(QUrl("file:///C:/Users/adhir/Development/PRISM/main.qml"))
        print("QML loaded.")


        # Ensure the QML file was loaded
        if not engine.rootObjects():
            print("Failed to load QML file!")
            sys.exit(-1)

        # Execute the application
        sys.exit(app.exec())

    except Exception as e:
        sys.exit(1)

