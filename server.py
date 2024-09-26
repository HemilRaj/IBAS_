import socket
import threading
import firebase_admin
from firebase_admin import credentials, storage, firestore
import cv2
import numpy as np
import face_recognition
import os
import re

# Initialize Firebase Admin SDK
cred = credentials.Certificate("ibas3-f5f24-firebase-adminsdk-vlfql-b0957ca3f2.json")
firebase_admin.initialize_app(cred)
storage_client = storage.bucket(name="ibas3-f5f24.appspot.com")  # Replace with your bucket name
db = firestore.client()  # Firestore database instance

def download_folders():
    download_folder = "downloaded_folders"
    if not os.path.exists(download_folder):
        os.makedirs(download_folder)

    folders_to_download = ["KnownFaces", "Class"]
    for folder_name in folders_to_download:
        blobs = storage_client.list_blobs(prefix=folder_name)
        for blob in blobs:
            if blob.name.endswith('/'):
                continue
            try:
                # Download folder contents to local storage
                folder_path = os.path.join(download_folder, os.path.dirname(blob.name))
                if not os.path.exists(folder_path):
                    os.makedirs(folder_path)
                blob.download_to_filename(os.path.join(download_folder, blob.name))
            except Exception as e:
                print(f"Error downloading {blob.name}: {e}")

def load_known_faces():
    known_face_encodings = []
    known_face_names = []

    folder_path = "downloaded_folders/KnownFaces"
    for subfolder_name in os.listdir(folder_path):
        subfolder_path = os.path.join(folder_path, subfolder_name)
        if os.path.isdir(subfolder_path):
            for image_file in os.listdir(subfolder_path):
                image_path = os.path.join(subfolder_path, image_file)
                try:
                    # Load image from local storage
                    image = cv2.imread(image_path)

                    # Encode face and store in known faces list
                    face_encoding = face_recognition.face_encodings(image)[0]
                    known_face_encodings.append(face_encoding)

                    # Use subfolder name as the face name
                    known_face_names.append(subfolder_name)
                except Exception as e:
                    print(f"Error processing image {image_path}: {e}")

    return known_face_encodings, known_face_names

def get_name_from_roll(rollNo):
    doc_ref = db.collection("registrations").document(rollNo)
    doc = doc_ref.get()
    if doc.exists:
        return doc.get("name")
    else:
        return None

def mark_attendance(name, rollNo, subject, attendance):
    attendance_ref = db.collection("attendance").document(f"{subject}_{rollNo}")
    attendance_ref.set({
        "date": firestore.SERVER_TIMESTAMP,
        "name": name,
        "rollNo": rollNo,
        "subject": subject,
        "attendance": attendance
    })

def mark_absent_students(subject):
    registrations_ref = db.collection("registrations")
    registrations = registrations_ref.stream()
    all_roll_numbers = [doc.id for doc in registrations]
    
    for rollNo in all_roll_numbers:
        if rollNo not in detected_faces:
            name = get_name_from_roll(rollNo)
            if name is not None:
                mark_attendance(name, rollNo, subject, "absent")

def extract_subject_name(image_file):
    match = re.search(r'(.*)\s+\d{4}-\d{2}-\d{2}\s+\d+\.(jpg|jpeg)', image_file)
    if match:
        subject_name = match.group(1)
        return subject_name
    else:
        return None

def recognize_faces():
    folder_path = "downloaded_folders/Class"
    for image_file in os.listdir(folder_path):
        image_path = os.path.join(folder_path, image_file)
        try:
            image = cv2.imread(image_path)
            
            subject = extract_subject_name(image_file)
            if subject:
                face_locations = face_recognition.face_locations(image)
                face_encodings = face_recognition.face_encodings(image, face_locations)

                print(f"Number of faces detected in {image_file}: {len(face_locations)}")

                for face_encoding, (top, right, bottom, left) in zip(face_encodings, face_locations):
                    cv2.rectangle(image, (left, top), (right, bottom), (0, 255, 0), 2)

                    matches = face_recognition.compare_faces(known_face_encodings, face_encoding)
                    if True in matches:
                        first_match_index = matches.index(True)
                        name = known_face_names[first_match_index]

                        rollNo = name
                        name = get_name_from_roll(rollNo)
                        if name is not None:
                            detected_faces.add(rollNo)
                            mark_attendance(name, rollNo, subject, "present")

                mark_absent_students(subject)

                cv2.imshow('Detected Faces', image)
                cv2.waitKey(0)
                cv2.destroyAllWindows()
            else:
                print(f"Subject name not found in image file name: {image_file}")
        except Exception as e:
            print(f"Error processing image {image_path}: {e}")

def handle_client(conn, addr):
    print(f"Connection from {addr}")
    try:
        download_folders()
        global known_face_encodings, known_face_names, detected_faces
        known_face_encodings, known_face_names = load_known_faces()
        detected_faces = set()
        recognize_faces()
        conn.send(b"Recognition process completed successfully")
    except Exception as e:
        conn.send(b"Error during recognition process: " + str(e).encode())
    conn.close()

def start_server():
    host = '172.28.115.113'  # Loopback address
    port = 5555  # Choose a port number

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind((host, port))
    server.listen()

    print(f"Server listening on {host}:{port}")

    while True:
        conn, addr = server.accept()
        thread = threading.Thread(target=handle_client, args=(conn, addr))
        thread.start()

if __name__ == "__main__":
    start_server()
