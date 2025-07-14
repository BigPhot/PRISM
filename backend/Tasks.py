from .LLM_API import gpt_api_call
import json
import re 
import os
from datetime import datetime
import sys

if getattr(sys, 'frozen', False):
    """
    Determine base directory when running inside a PyInstaller bundle.
    """
    BASE_DIR = sys._MEIPASS
else:
    # Determine base directory when running normally.

    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Uses the base directory to create the necessary file paths
TASKS_FILE = os.path.join(BASE_DIR, "..", "data", "Prism_Task_Data.json")
ACTIVITY_FILE = os.path.join(BASE_DIR, "..", "data", "Task_Activity_Log.json")

def set_tasks_file(new_path):
    """
    Update the global path to the tasks JSON file.
    """
    global TASKS_FILE
    TASKS_FILE = new_path


def create_task(usr_inp):
    """
    Creates a structured task from user input using the GPT API and saves it to file.

    Parameters:
    usr_inp (str): The raw user input describing the task to create.
    """
    rule = (
        "The default response for tasks should be formatted as a JSON file with the following structure: "
        "- **Title**: Task title. "
        "- **Description**: A description without phrases like 'The process includes.' "
        "- **Steps**: A numbered list of steps without sub-numbering, each under 100 characters. "
        "- **Estimated Total Time**: A time estimate for completion."
    )
    
    # Call GPT API with user input and rule
    task_breakdown = gpt_api_call(usr_inp, rule)
    print(task_breakdown)

    # Extract JSON from string if necessary
    if isinstance(task_breakdown, str):
        match = re.search(r'\{.*\}', task_breakdown, re.DOTALL)
        if match:
            json_output = match.group(0)
            parsed_json = json.loads(json_output)
        else:
            raise ValueError("No valid JSON found in the GPT response.")
    else:
        parsed_json = task_breakdown

    # Save task to file with default category "idea"
    save_task_to_file_with_category(parsed_json)


def move_task(tasks, fromIndex, toIndex, category):
    """
    Swap two tasks in the given task list and update the persistent JSON file.

    Parameters:
    tasks (list): List of tasks filtered by the specified category.
    fromIndex (int): The index of the task to move from.
    toIndex (int): The index of the task to move to.
    category (str): The category of tasks being modified.
    """
    # Validate indices before proceeding
    if not (0 <= fromIndex < len(tasks)) or not (0 <= toIndex < len(tasks)):
        print(f"Invalid move: from {fromIndex} to {toIndex}")
        return

    # Swap the tasks in-place
    tasks[fromIndex], tasks[toIndex] = tasks[toIndex], tasks[fromIndex]

    # Load all tasks from file
    with open(TASKS_FILE, "r", encoding="utf-8") as f:
        all_tasks = json.load(f)

    # Filter out tasks belonging to the current category
    other_tasks = [t for t in all_tasks if t.get("category") != category]

    # Combine untouched tasks with the updated category-specific task list
    combined = other_tasks + tasks

    # Persist the combined task list back to the JSON file
    with open(TASKS_FILE, "w", encoding="utf-8") as f:
        json.dump(combined, f, indent=4)


def move_tasks_category(fromCategory, index, toCategory):
    """
    Move a task from one category to another by its index within the source category.

    Parameters:
    fromCategory (str): The category to move the task from.
    index (int): The index of the task in the source category to move.
    toCategory (str): The category to move the task to.
    """
    with open(TASKS_FILE, "r", encoding="utf-8") as f:
        all_tasks = json.load(f)

    # Separate tasks in source category and others
    from_tasks = [t for t in all_tasks if t["category"] == fromCategory]
    other_tasks = [t for t in all_tasks if t["category"] != fromCategory]

    # Safely remove the task at index from the source category tasks
    if index < 0 or index >= len(from_tasks):
        raise IndexError(f"Index {index} out of range for category '{fromCategory}' with {len(from_tasks)} tasks")

    task = from_tasks.pop(index)
    task["category"] = toCategory

    # Reassemble the tasks list: tasks not in source category + updated source category tasks + moved task at the end
    all_tasks = other_tasks + from_tasks + [task]

    with open(TASKS_FILE, "w", encoding="utf-8") as f:
        json.dump(all_tasks, f, indent=4)



def move_step(submenu_items, dev_menu_items, selected_index, from_index, to_index):
    """
    Reorder steps within a submenu and update the corresponding dev menu item's steps.

    Parameters:
    submenu_items (list): List of steps in the submenu.
    dev_menu_items (list): List of dev menu tasks.
    selected_index (int): Index of the selected dev menu item.
    from_index (int): Current index of the step to move.
    to_index (int): Target index to move the step to.
    """
    # Validate step indices
    if not (0 <= from_index < len(submenu_items)) or not (0 <= to_index < len(submenu_items)):
        print(f"Invalid step move: from {from_index} to {to_index}")
        return

    # Move the step in the list
    step = submenu_items.pop(from_index)
    submenu_items.insert(to_index, step)

    # Update dev menu item if index valid
    if 0 <= selected_index < len(dev_menu_items):
        dev_menu_items[selected_index]["steps"] = submenu_items

        # Load all tasks and update steps for the matched dev task
        with open(TASKS_FILE, "r", encoding="utf-8") as f:
            all_tasks = json.load(f)

        for task in all_tasks:
            if (
                task.get("category") == "dev" and
                task.get("title") == dev_menu_items[selected_index]["title"]
            ):
                task["steps"] = submenu_items
                break

        # Save updated tasks list back to file
        with open(TASKS_FILE, "w", encoding="utf-8") as f:
            json.dump(all_tasks, f, indent=4)
    else:
        print("Selected dev menu index is out of bounds.")


def save_task_to_file_with_category(task, category="idea", index=None):
    """
    Save a new task to the tasks JSON file under the specified category.
    If an index is provided, insert the task at that position; otherwise, append it.

    Parameters:
    task (dict): Task data with keys 'Title', 'Description', 'Steps', and 'Estimated Total Time'.
    category (str): Category to assign to the new task. Defaults to "idea".
    index (int or None): Optional position to insert the task. Appends if None or invalid.
    """
    # Load existing tasks or initialize an empty list if file missing or invalid
    if os.path.exists(TASKS_FILE):
        with open(TASKS_FILE, "r", encoding="utf-8") as file:
            try:
                tasks = json.load(file)
                if not isinstance(tasks, list):
                    tasks = []
            except json.JSONDecodeError:
                tasks = []
    else:
        tasks = []

    # Format steps to include description and default duration
    formatted_steps = [{"description": step, "duration": 0} for step in task["Steps"]]

    new_task = {
        "title": task["Title"],
        "description": task["Description"],
        "priority": 5,
        "expectedTime": task["Estimated Total Time"],
        "elapsedTime": 0,
        "category": category,
        "steps": formatted_steps
    }

    # Insert at index or append to the task list
    if index is not None and 0 <= index <= len(tasks):
        tasks.insert(index, new_task)
    else:
        tasks.append(new_task)

    # Save updated tasks list back to file
    with open(TASKS_FILE, "w", encoding="utf-8") as file:
        json.dump(tasks, file, indent=4, ensure_ascii=False)

    print(f"✅ Task saved to {TASKS_FILE}")


def expand_step(usr_stp):
    """
    Expand a single task step into multiple detailed sub-steps using GPT.
    Update the task JSON file by replacing the original step with the new sub-steps.

    Parameters:
    usr_stp (dict): Contains 'title', 'description', and 'step_to_expand' keys to identify
                    the task and the step to expand.
    """
    rule = (
        "When given a JSON input containing 'title', 'description', and 'step_to_expand', break the specified step into detailed actions."
        "Return a JSON with the structure: 'Steps' as a list of objects, each containing a 'Description' of a detailed action or sub-step."
        "Each step should be under a 100 characters. Do not include titles or additional descriptions."
    )
    expanded_steps_str = gpt_api_call(usr_stp, rule)

    try:
        expanded_steps = json.loads(expanded_steps_str)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON from gpt_api_call: {e}")
        print(f"Raw response: {expanded_steps_str}")
        return

    try:
        with open(TASKS_FILE, 'r') as file:
            json_data = json.load(file)
    except FileNotFoundError:
        print(f"Error: File not found at {TASKS_FILE}")
        return
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON format in {TASKS_FILE}")
        return

    found_main_index = -1
    found_index = -1

    # Find the matching task and step indices
    for main_index, item in enumerate(json_data):
        if isinstance(item, dict) and 'title' in item and 'description' in item:
            if item['title'] == usr_stp['title'] and item['description'] == usr_stp['description']:
                found_main_index = main_index
                for index, step in enumerate(item['steps']):
                    if step['description'] == usr_stp['step_to_expand']:
                        found_index = index
                        break
                break

    if (
        expanded_steps and
        'Steps' in expanded_steps and
        isinstance(expanded_steps['Steps'], list) and
        expanded_steps['Steps']
    ):
        formatted_steps = [{"description": step['Description'], "duration": 0} for step in expanded_steps['Steps']]

        # Replace original step with expanded sub-steps
        if found_index != -1 and found_main_index != -1:
            json_data[found_main_index]['steps'][found_index + 1:found_index + 1] = formatted_steps
            del json_data[found_main_index]['steps'][found_index]

            with open(TASKS_FILE, 'w') as f:
                json.dump(json_data, f, indent=4)

            print(f"JSON file updated successfully at {TASKS_FILE}")
        else:
            print("Step to expand not found.")
    else:
        print("Error: expanded_steps does not contain the expected structure.")


def combine_steps(usr_stps):
    """
    Combines multiple user-defined steps into a single concise step in a JSON task file.

    Parameters:
    usr_stps (dict): A dictionary with 'title', 'description', and 'steps_to_combine'.
    """
    rule = (
        "When given a JSON input containing 'title', 'description', and 'steps_to_combine', merge the listed steps into a single, concise step that maintains the essence of all included actions."
        "Return a JSON with the structure where 'Step' contains a single, cohesive step combining all provided steps, and under a 100 characters. Do not include titles or additional descriptions beyond the combined step."
    )

    combined_step_str = gpt_api_call(usr_stps, rule)

    try:
        combined_step = json.loads(combined_step_str)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON from gpt_api_call: {e}")
        print(f"Raw response: {combined_step_str}")
        return

    try:
        with open(TASKS_FILE, 'r') as file:
            json_data = json.load(file)
    except FileNotFoundError:
        print(f"Error: File not found at {TASKS_FILE}")
        return
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON format in {TASKS_FILE}")
        return

    found_main_index = None
    found_indices = []

    # Locate the main task by matching title and description
    for main_index, item in enumerate(json_data):
        if isinstance(item, dict) and 'title' in item and 'description' in item:
            if item['title'] == usr_stps['title'] and item['description'] == usr_stps['description']:
                found_main_index = main_index

                # Identify indices of steps to combine
                for index, step in enumerate(item['steps']):
                    if step['description'] in usr_stps['steps_to_combine']:
                        found_indices.append(index)

                break  # Exit after finding the correct task

    if found_main_index is not None and found_indices:
        # Remove steps in reverse order to avoid index shifting
        found_indices.sort(reverse=True)
        for index in found_indices:
            del json_data[found_main_index]['steps'][index]

        # Insert the new combined step at the earliest removed step's position
        formatted_combined_step = {"description": combined_step['Step'], "duration": 0}
        insertion_index = min(found_indices)
        json_data[found_main_index]['steps'].insert(insertion_index, formatted_combined_step)

        # Write updated data back to the JSON file
        with open(TASKS_FILE, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, indent=4)

        print(f"Updated JSON file at {TASKS_FILE}")
    else:
        print("Error: Could not find the steps to replace.")


def add_step(usr_inp, task_index):
    """
    Adds a new step to a development task based on user input.

    Parameters:
    usr_inp (str): The raw step text to be refined and added.
    task_index (int): Index of the dev task in the filtered list of development tasks.
    """
    try:
        with open(TASKS_FILE, 'r', encoding='utf-8') as file:
            json_data = json.load(file)
    except FileNotFoundError:
        print(f"Error: File not found at {TASKS_FILE}")
        return

    # Filter all development tasks and get their indices in the full list
    dev_task_indices = [i for i, task in enumerate(json_data) if task.get("category") == "dev"]

    if task_index >= len(dev_task_indices):
        print(f"Error: task_index {task_index} out of range for dev tasks.")
        return

    full_list_index = dev_task_indices[task_index]
    dev_task = json_data[full_list_index]

    rule = (
        "When given a JSON input containing 'title', 'description', and 'steps_to_add' rewrite the step so that it clearly and concisely supports the completion of the task described. "
        "Return it in a json object called 'step' which is under a 100 characters"
    )

    step_data = {
        'title': dev_task['title'],
        'description': dev_task['description'],
        'step_to_add': usr_inp
    }

    new_step_breakdown_str = gpt_api_call(step_data, rule)

    if not new_step_breakdown_str:
        print("Error: The response from gpt_api_call is empty or None.")
        return

    # Clean up GPT response for safe JSON parsing
    new_step_breakdown_str = new_step_breakdown_str.strip().replace('`', '')
    new_step_breakdown_str = re.sub(r'^\s*json\s*', '', new_step_breakdown_str).strip()

    try:
        new_step_breakdown = json.loads(new_step_breakdown_str)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse response as JSON. {e}")
        return

    new_step = {
        "description": new_step_breakdown["step"],
        "duration": 0
    }

    # Insert new step at the top of the dev task's steps
    json_data[full_list_index]["steps"].insert(0, new_step)

    # Persist updated task list to file
    with open(TASKS_FILE, "w", encoding="utf-8") as file:
        json.dump(json_data, file, indent=4, ensure_ascii=False)

    print("✅ Step added and task updated successfully.")


def delete_step(usr_stp):
    """
    Delete a specified step from a task in the tasks JSON file.

    Parameters:
    usr_stp (dict): Contains 'title', 'description', and 'step_to_delete' keys to identify
                    the task and the step to be deleted.
    """
    # Load existing tasks from file
    try:
        with open(TASKS_FILE, 'r', encoding='utf-8') as file:
            json_data = json.load(file)
    except FileNotFoundError:
        print(f"Error: File not found at {TASKS_FILE}")
        return
    except json.JSONDecodeError:
        print("Error: Failed to parse JSON data.")
        return

    step_deleted = False

    # Find the matching task and remove the specified step
    for menu in json_data:
        if menu["title"] == usr_stp['title'] and menu["description"] == usr_stp['description']:
            original_count = len(menu.get("steps", []))
            menu["steps"] = [
                step for step in menu.get("steps", [])
                if step["description"] != usr_stp["step_to_delete"]
            ]
            if len(menu["steps"]) < original_count:
                step_deleted = True
                break

    if step_deleted:
        # Save updated tasks back to file
        try:
            with open(TASKS_FILE, 'w', encoding='utf-8') as f:
                json.dump(json_data, f, indent=4, ensure_ascii=False)
            print("Step deleted and file updated successfully.")
            # If this is inside a class, emit the signal like:
            # self.menuItemsChanged.emit()
        except Exception as e:
            print(f"Error writing to file: {e}")
    else:
        print(f"Step '{usr_stp['step_to_delete']}' not found in task '{usr_stp['title']}' - '{usr_stp['description']}'")


def log_time(usr_time):
    """
    Update the duration of a specified step in a task and log the activity.

    Parameters:
    usr_time (dict): Contains keys 'title', 'description', 'step_to_record', and 'duration' (in seconds).
    """
    # Load tasks data from file
    try:
        with open(TASKS_FILE, 'r', encoding='utf-8') as file:
            data = json.load(file)
    except FileNotFoundError:
        print(f"Error: File not found at {TASKS_FILE}")
        return
    except json.JSONDecodeError:
        print("Error: Could not decode JSON.")
        return

    updated = False

    # Find task and step to update duration
    for task in data:
        if task["title"] == usr_time["title"] and task["description"] == usr_time["description"]:
            for step in task["steps"]:
                if step["description"] == usr_time["step_to_record"]:
                    print(f"Updating step duration: {step['description']} -> {usr_time['duration']}")
                    step["duration"] = int(step.get("duration", 0)) + int(usr_time["duration"])
                    updated = True
                    break  
            break  

    # Save updated tasks back to file if a step was updated
    if updated:
        try:
            with open(TASKS_FILE, 'w', encoding='utf-8') as file:
                json.dump(data, file, indent=4, ensure_ascii=False)
            print("Duration updated and file saved.")
        except Exception as e:
            print(f"Error writing updated data: {e}")
    else:
        print("Matching step not found; nothing was updated.")

    # Log the activity separately
    try:
        # Load existing activity log or initialize an empty list
        try:
            with open(ACTIVITY_FILE, 'r', encoding='utf-8') as file:
                data = json.load(file)
        except FileNotFoundError:
            print(f"Activity file not found at {ACTIVITY_FILE}. Creating a new one.")
            data = []
        except json.JSONDecodeError:
            print("Error: Could not decode JSON in activity log.")
            data = []

        # Convert duration in seconds to H:M:S format
        hours, remainder = divmod(int(usr_time["duration"]), 3600)
        mins, secs = divmod(remainder, 60)

        match = re.search(r'([^\\/]+)_Task_Data\.json$', usr_time["project"])
        if match:
            word = match.group(1)

        new_entry = {
            "project": word,
            "title": usr_time["title"],
            "description": usr_time["step_to_record"],
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "duration": f"{hours}:{mins:02d}:{secs:02d}"
        }

        # Append new activity entry and save
        data.append(new_entry)
        with open(ACTIVITY_FILE, "w", encoding="utf-8") as file:
            json.dump(data, file, indent=4, ensure_ascii=False)
        print("✅ Activity logged.")
    except Exception as e:
        print(f"Unexpected error during activity logging: {e}")


def add_context(usr_inp, task_index):
    """
    Update a 'dev' category task by adding user-provided context and refreshing its breakdown.

    Parameters:
    usr_inp (str): User input providing additional context to update the task.
    task_index (int): Index of the 'dev' task to update, relative to all 'dev' tasks.
    """
    try:
        with open(TASKS_FILE, 'r', encoding='utf-8') as file:
            json_data = json.load(file)
    except FileNotFoundError:
        print(f"Error: File not found at {TASKS_FILE}")
        return

    # Find all dev tasks and their indices in the full list
    dev_task_indices = [i for i, task in enumerate(json_data) if task.get("category") == "dev"]

    # Validate the provided index
    if task_index >= len(dev_task_indices):
        print(f"Error: task_index {task_index} out of range for dev tasks.")
        return

    full_list_index = dev_task_indices[task_index]
    dev_task = json_data[full_list_index]

    rule = (
        "When modifying or updating the task breakdown, always respond with a JSON object "
        "that includes the updated title, description, steps, and estimated total time. "
        "Each step should be under 100 characters. The JSON must accurately reflect any context changes provided by the user."
    )

    # Prepare input for GPT API with existing task data plus new context
    ai_inp = "Task Input: " + str(dev_task) + "\nContext Input: " + usr_inp

    new_task_breakdown_str = gpt_api_call(ai_inp, rule)

    if not new_task_breakdown_str:
        print("Error: The response from gpt_api_call is empty or None.")
        return

    # Clean the response string to prepare for JSON parsing
    new_task_breakdown_str = new_task_breakdown_str.strip().replace('`', '')
    new_task_breakdown_str = re.sub(r'^\s*json\s*', '', new_task_breakdown_str).strip()

    try:
        new_task_breakdown = json.loads(new_task_breakdown_str)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse response as JSON. {e}")
        return

    # Extract step descriptions, handling both dict and string formats
    raw_steps = new_task_breakdown.get("steps", [])
    if raw_steps and isinstance(raw_steps[0], dict):
        step_descriptions = [step.get("description", "") for step in raw_steps]
    else:
        step_descriptions = raw_steps

    # Build updated task dictionary, preserving some old fields
    updated_task = {
        "title": new_task_breakdown.get("title", dev_task.get("title", "")),
        "description": new_task_breakdown.get("description", dev_task.get("description", "")),
        "priority": dev_task.get("priority", 5),
        "expectedTime": new_task_breakdown.get("estimatedTotalTime", dev_task.get("expectedTime", "1 hour")),
        "elapsedTime": dev_task.get("elapsedTime", 0),
        "category": "dev",
        "steps": [{"description": desc, "duration": 0} for desc in step_descriptions]
    }

    # Replace old task with updated task in full task list
    json_data[full_list_index] = updated_task

    # Save updated list back to the tasks file
    with open(TASKS_FILE, "w", encoding="utf-8") as file:
        json.dump(json_data, file, indent=4, ensure_ascii=False)

    print("✅ Task updated in full list and saved.")


