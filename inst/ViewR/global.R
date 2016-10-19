library(dplyr)
library(gitfiles)

repo_directory <- "/Users/kaplan/KaplanFiles/Courses/math253-students/Repositories/"

# Bring in the log file
COMMIT_LOG <- readRDS(paste0(repo_directory, "LOGFILE.rds"))
STUDENTS <- gitfiles:::read_student_file(dir = repo_directory)
ASSIGNMENTS <- gitfiles:::read_assignment_file(dir = repo_directory)
GRADES <- gitfiles:::read_grade_file(dir = repo_directory)
THESE_FILES <- NULL

write_grades <- function(grade_df) {
  if (all(c("date", "id", "assignment","grade", "commit") %in% names(grade_df))) {
    saveRDS(grade_df,
            paste0(repo_directory, "GRADES.rds"))
  } else {
    warning("Broken format in GRADES data frame.")
  }
}



# format file names nicely

get_available_files <- function(Log, .id = NULL, .assignment = NULL) {
  # if .id or .assignment is NULL, give back files for all
  # ids or all assignments

  Log %>%
    group_by(id, assignment, file_name) -> tmp
  if ( ! is.null(.id)) {
    tmp %>%
      filter(id %in% .id) -> tmp
  }
  if ( ! is.null(.assignment)) {
    tmp %>%
      filter(assignment %in% .assignment) -> tmp
  }

  tmp %>% filter(date == max(date))
}

# Also add in here, eventually, whether the file has been graded.

format_file_names <- function(Log, id = NULL, assignment = NULL) {
  THESE_FILES <<-
    get_available_files(Log, .id = id, .assignment = assignment) %>%
    group_by(id, assignment) %>%
    filter(date == max(date)) %>%
    arrange(id, assignment) %>%
    filter(row_number() == 1) %>%
    ungroup()
  assignmentGrades <-
    GRADES %>%
    group_by(id, assignment) %>%
    filter(date == max(date)) %>%
    filter(row_number() == 1) %>%
    ungroup() %>%
    rename(grade_date = date, grade_commit = commit)

  THESE_FILES <-
    THESE_FILES %>%
    rename(commit_comment = comment) %>%
    left_join(assignmentGrades) %>%
    mutate(regrade = ifelse(grade_date < date, "*", " ")) %>%
    mutate(has_comment = ifelse(nchar(comment) > 1, "+", ""))

  display_names <-   THESE_FILES %>%
    with( .,
          paste0(assignment, " :: ", id, "  ",
                 ifelse(is.na(grade), " ", grade), ifelse(is.na(regrade), " ", regrade),
                 ifelse(is.na(has_comment), "", has_comment))

          )
  res <- as.list(1:length(display_names))
  names(res) <- display_names

  res
}