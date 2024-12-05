release: gen
	cp target/release/libbobthetiler.so ../thparty/include/lib/linux_64/
	mkdir -p ../thparty/include/bobthetiler
	cp layout_tree.h ../thparty/include/bobthetiler/

gen:
	cbindgen --config cbindgen.toml --crate bobthetiler --output layout_tree.h
	cargo build --release
