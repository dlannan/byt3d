--
-- Created by David Lannan
-- User: grover
-- Date: 19/04/13
-- Time: 12:04 AM
-- Copyright 2013  Developed for use with the byt3d engine.
--

local ffi   = require( "ffi" )

ffi.cdef[[

    typedef struct dirent {
        long ino;
        char d_name[4096 + 1];
    } dirent;

    //* DIR substitute structure containing directory name.  The name is
    //* essential for the operation of ``rewinndir'' function. */
    typedef struct DIR {
        int         fd;
        dirent      current;                     //* current entry */
    } DIR;

    //* supply prototypes for dirent functions */
    DIR *           opendir (const char *dirname);
    dirent *        readdir (DIR *dirp);
    int             closedir (DIR *dirp);
    void            rewinddir (DIR *dirp);

   struct stat   /* inode information returned by stat */
   {
       dev_t     st_dev;      /* device of inode */
       ino_t     st_ino;      /* inode number */
       short     st_mode;     /* mode bits */
       short     st_nlink;    /* number of links to file */
       short     st_uid;      /* owners user id */
       short     st_gid;      /* owners group id */
       dev_t     st_rdev;     /* for special files */
       off_t     st_size;     /* file size in characters */
       time_t    st_atime;    /* time last accessed */
       time_t    st_mtime;    /* time last modified */
       time_t    st_ctime;    /* time originally created */
   };

    enum {
        S_IFMT    0160000,  //* type of file: */
        S_IFDIR   0040000,  //* directory */
        S_IFCHR   0020000,  //* character special */
        S_IFBLK   0060000,  //* block special */
        S_IFREG   0010000   //* regular */
    };
]]