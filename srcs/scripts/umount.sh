
echo "Unmounting $LFS_IMG..."
guestunmount $LFS && \
rmdir $LFS && \
echo "Unmount successfully!"
