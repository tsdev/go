# go
The MATLAB cd command on steroids

Save, go to, go back and retrieve folders identified by arbitrary label

`GO(label,path)`

Adds path and the corresponding label to the list of saved path. If the
label already exists, it will be overwritten. The command automatically
exchange the user home folder path to '~' for unix based systems.

`GO`

Prints all label - path pairs to the Command Window.

`GO(label)`

Changes the directory to the path based on the following rules in order
of precedence:
  -   if the label is a valid path the command is equivalent to the
      MATLAB built-in cd command
  -   if the label is a matlab function, the new path is the folder of
      the function
  -   if the label exists in the go.db file, go to the corresponding
      folder
If none of the above rules are fulfilled, gives a warning.
path = GO(label)
Returns the path that corresponds to the given label.

`GO clear`

Clears the database.

`Go back`

Goes back to the previous path from where GO() was called last time. Can
be only used to go back one level.

`GO label here`

To abel to use the command without string notation and brackets, the here
string is automaticelly replaced by the output of the pwd() function
(current path).
The labels are case sensitive. The list of label path pairs are saved
into the text file $USERPATH/go.db.
